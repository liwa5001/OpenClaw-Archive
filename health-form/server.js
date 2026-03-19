#!/usr/bin/env node
/**
 * 健康堡问卷表单服务器 v2.0
 * 接收表单提交，解析数据，更新统计文件，发送飞书确认
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.PORT || 8897;
const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const STATS_DIR = path.join(WORKSPACE, 'daily-output/health/daily-stats');
const LOG_PATH = path.join(WORKSPACE, 'logs/health-form.log');

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(LOG_PATH, logLine);
    console.log(logLine.trim());
}

/**
 * 计算评分
 */
function calculateScores(data) {
    const scores = {
        exercise: 0,
        food: 0,
        sleep: 0,
        total: 0
    };
    
    // 运动评分（40 分）
    if (data.exercise_status === '1') {
        scores.exercise = 40;
    } else {
        scores.exercise = 30;
    }
    
    // 饮食评分（30 分）- 基于记录完整度
    let foodCount = 0;
    if (data.food_breakfast && data.food_breakfast.trim()) foodCount++;
    if (data.food_lunch && data.food_lunch.trim()) foodCount++;
    if (data.food_dinner && data.food_dinner.trim()) foodCount++;
    scores.food = Math.round(foodCount / 3 * 30);
    
    // 睡眠评分（30 分）
    const sleepRating = parseInt(data.sleep_rating) || 3;
    scores.sleep = sleepRating * 6;
    
    scores.total = scores.exercise + scores.food + scores.sleep;
    
    return scores;
}

/**
 * 生成建议
 */
function generateSuggestions(data, scores) {
    const suggestions = [];
    
    // 运动建议
    if (data.exercise_status === '0') {
        suggestions.push('🏃 今天安排一次恢复性运动吧！Z2 骑行 30-45km');
    } else {
        const duration = parseInt(data.exercise_duration) || 0;
        if (duration > 120) {
            suggestions.push('💪 训练量较大，注意充分恢复');
        } else {
            suggestions.push('💪 运动状态良好，继续保持！');
        }
    }
    
    // 饮食建议
    if (!data.food_breakfast || !data.food_breakfast.trim()) {
        suggestions.push('🍽️ 建议吃早餐，开启一天新陈代谢');
    }
    if (data.food_snack && data.food_snack.trim()) {
        suggestions.push('🍽️ 有夜宵记录，建议尽量避免，有助于睡眠和减脂');
    }
    if (!data.food_dinner || !data.food_dinner.trim()) {
        suggestions.push('🍽️ 晚餐不宜过晚，建议 19:00 前完成');
    }
    
    // 睡眠建议
    const sleepRating = parseInt(data.sleep_rating) || 3;
    if (sleepRating < 3) {
        suggestions.push('😴 睡眠质量一般，今晚尝试提前 30 分钟入睡');
    }
    if (data.sleep_rhr && parseInt(data.sleep_rhr) > 60) {
        suggestions.push('😴 静息心率偏高，可能与疲劳或压力有关');
    }
    if (data.sleep_deep && parseFloat(data.sleep_deep) < 1.5) {
        suggestions.push('😴 深睡时间偏短，建议避免睡前使用电子设备');
    }
    
    return suggestions;
}

/**
 * 更新统计文件
 */
function updateStatsFile(data, date) {
    const statsFile = path.join(STATS_DIR, `${date}-health-stats.md`);
    
    const scores = calculateScores(data);
    const suggestions = generateSuggestions(data, scores);
    
    // 计算睡眠时长
    let sleepDuration = '-';
    let totalSleepStages = 0;
    if (data.sleep_bedtime && data.sleep_waketime) {
        const bedtime = new Date(`2000-01-01T${data.sleep_bedtime}`);
        const waketime = new Date(`2000-01-01T${data.sleep_waketime}`);
        let diffMs = waketime - bedtime;
        if (diffMs < 0) diffMs += 24 * 60 * 60 * 1000;
        sleepDuration = (diffMs / (60 * 60 * 1000)).toFixed(1);
    }
    if (data.sleep_deep) totalSleepStages += parseFloat(data.sleep_deep);
    if (data.sleep_light) totalSleepStages += parseFloat(data.sleep_light);
    if (data.sleep_rem) totalSleepStages += parseFloat(data.sleep_rem);
    
    // 生成 Markdown 内容
    const content = `---
type: health-daily-stats
date: ${date}
agent: health-castle
version: v3.0
data_sources:
  - strava: data/strava/latest-activities.json
  - 用户问卷：health-form 表单提交
  - 睡眠监测：用户填写
---

# 📊 健康堡每日统计 | ${date}

**生成时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}  
**数据完整度：** 运动✅ | 睡眠✅ | 饮食✅  
**状态：** ✅ 数据已完整

---

## 🏃 今日运动

| 指标 | 数值 | 单位 | 备注 |
|------|------|------|------|
| 训练状态 | ${data.exercise_status === '1' ? '✅ 有记录' : '😴 休息日'} | - | - |
| 运动类型 | ${data.exercise_type || '-'} | - | - |
| 运动时长 | ${data.exercise_duration || '-'} | 分钟 | - |
| 运动距离 | ${data.exercise_distance || '-'} | km | - |
| 运动感受 | ${data.exercise_rating ? data.exercise_rating + '/5' : '-'} | 分 | - |

---

## 🍽️ 饮食记录

| 餐次 | 时间 | 内容 | 估算卡路里 |
|------|------|------|-----------|
| 早餐 | ${data.food_breakfast_time || '-'} | ${data.food_breakfast || '未填写'} | 待计算 |
| 午餐 | ${data.food_lunch_time || '-'} | ${data.food_lunch || '未填写'} | 待计算 |
| 晚餐 | ${data.food_dinner_time || '-'} | ${data.food_dinner || '未填写'} | 待计算 |
| 夜宵 | ${data.food_snack_time || '-'} | ${data.food_snack || '无'} | 待计算 |
| **总计** | - | - | **待计算 kcal** |

**饮食类型：** 待分析  
**16+8 断食：** ${calculateIF(data)}

---

## 😴 睡眠质量

| 指标 | 数值 | 单位 | 评估 |
|------|------|------|------|
| 睡眠评分 | ${data.sleep_rating || '-'}/5 | 分 | ${getSleepQualityText(data.sleep_rating)} |
| 入睡时间 | ${data.sleep_bedtime || '-'} | - | 目标 23:00 |
| 起床时间 | ${data.sleep_waketime || '-'} | - | - |
| 睡眠时长 | ${sleepDuration} | 小时 | 目标 7.5h |
| 深睡时长 | ${data.sleep_deep || '-'} | 小时 | ${getSleepStageText(data.sleep_deep, 'deep')} |
| 浅睡时长 | ${data.sleep_light || '-'} | 小时 | - |
| REM 时长 | ${data.sleep_rem || '-'} | 小时 | ${getSleepStageText(data.sleep_rem, 'rem')} |
| 总睡眠阶段 | ${totalSleepStages > 0 ? totalSleepStages.toFixed(1) : '-'} | 小时 | - |
| 静息心率 | ${data.sleep_rhr || '-'} | bpm | ${getRHRText(data.sleep_rhr)} |

---

## ⚖️ 体重追踪

| 指标 | 数值 | 单位 | 备注 |
|------|------|------|------|
| 今晨体重 | ${data.weight || '-'} | kg | ${isMonday(date) ? '周一测量' : '非周一'} |

---

## 📊 今日评分

| 维度 | 评分 | 满分 | 完成度 | 说明 |
|------|------|------|--------|------|
| 运动达标 | ${scores.exercise}/40 | 40 | ${Math.round(scores.exercise*100/40)}% | ${data.exercise_status === '1' ? '有运动' : '休息日'} |
| 饮食健康 | ${scores.food}/30 | 30 | ${Math.round(scores.food*100/30)}% | 基于记录完整度 |
| 睡眠质量 | ${scores.sleep}/30 | 30 | ${Math.round(scores.sleep*100/30)}% | 基于自评 |
| **综合评分** | **${scores.total}/100** | **100** | **${scores.total}%** | **${getScoreText(scores.total)}** |

---

## 💡 明日建议

${suggestions.map(s => s).join('\n\n')}

---

## 📝 数据来源

**提交方式：** 健康堡问卷表单  
**提交时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}

---

🏰 城堡健康堡 | 科学训练，持续进步！💪
`;

    fs.writeFileSync(statsFile, content, 'utf8');
    log(`✅ 统计文件已更新：${statsFile}`);
    
    return { scores, suggestions, sleepDuration, totalSleepStages };
}

/**
 * 计算 16+8 断食
 */
function calculateIF(data) {
    if (!data.food_breakfast_time || !data.food_dinner_time) {
        return '待计算';
    }
    
    const breakfast = data.food_breakfast_time.split(':').map(Number);
    const dinner = data.food_dinner_time.split(':').map(Number);
    
    const breakfastMin = breakfast[0] * 60 + breakfast[1];
    let dinnerMin = dinner[0] * 60 + dinner[1];
    if (dinnerMin < breakfastMin) dinnerMin += 24 * 60;
    
    const eatingWindow = (dinnerMin - breakfastMin) / 60;
    const fastingHours = 24 - eatingWindow;
    
    if (fastingHours >= 16) {
        return `✅ ${fastingHours.toFixed(1)}h (达标)`;
    } else {
        return `❌ ${fastingHours.toFixed(1)}h (未达标)`;
    }
}

/**
 * 发送飞书确认消息
 */
function sendFeishuConfirmation(data, date, scores, suggestions, sleepDuration, totalSleepStages) {
    const exerciseText = data.exercise_status === '1' 
        ? `${data.exercise_type} ${data.exercise_duration}分钟${data.exercise_distance ? ` (${data.exercise_distance}km)` : ''}`
        : '休息日';
    
    const foodText = [];
    if (data.food_breakfast && data.food_breakfast.trim()) foodText.push('✅ 早餐');
    if (data.food_lunch && data.food_lunch.trim()) foodText.push('✅ 午餐');
    if (data.food_dinner && data.food_dinner.trim()) foodText.push('✅ 晚餐');
    if (data.food_snack && data.food_snack.trim()) foodText.push('⚠️ 夜宵');
    
    const sleepStagesText = [];
    if (data.sleep_deep) sleepStagesText.push(`深睡${data.sleep_deep}h`);
    if (data.sleep_light) sleepStagesText.push(`浅睡${data.sleep_light}h`);
    if (data.sleep_rem) sleepStagesText.push(`REM${data.sleep_rem}h`);
    
    const message = `✅ 收到！${date} 健康数据已记录

【运动】${exerciseText}
${data.exercise_status === '1' ? `感受：${data.exercise_rating}/5 分` : ''}

【饮食】${foodText.length > 0 ? foodText.join(' ') : '⚠️ 部分未填写'}
${data.food_breakfast_time ? `早餐：${data.food_breakfast_time}` : ''}
${data.food_dinner_time ? `晚餐：${data.food_dinner_time}` : ''}
${calculateIF(data) !== '待计算' ? `16+8 断食：${calculateIF(data)}` : ''}

【睡眠】${data.sleep_rating}/5 分 | ${sleepDuration}小时 | ${data.sleep_bedtime}-${data.sleep_waketime}
${sleepStagesText.length > 0 ? `睡眠阶段：${sleepStagesText.join(' | ')}` : ''}
${totalSleepStages > 0 ? `总阶段时长：${totalSleepStages.toFixed(1)}小时` : ''}
${data.sleep_rhr ? `静息心率：${data.sleep_rhr}bpm` : ''}

${data.weight ? `【体重】${data.weight}kg` : ''}

【今日评分】
🏃 运动：${scores.exercise}/40 ${scores.exercise >= 30 ? '✅' : '⚠️'}
🍽️ 饮食：${scores.food}/30 ${scores.food >= 20 ? '✅' : '⚠️'}
😴 睡眠：${scores.sleep}/30 ${scores.sleep >= 20 ? '✅' : '⚠️'}
**综合：${scores.total}/100** ${getScoreText(scores.total)}

【明日建议】
${suggestions.join('\n')}

继续加油！💪

🏰 城堡健康堡`;

    try {
        const cmd = `/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "${message.replace(/"/g, '\\"')}"`;
        execSync(cmd, { stdio: 'pipe' });
        log('✅ 确认消息已发送（飞书）');
    } catch (e) {
        log(`❌ 发送失败：${e.message}`);
    }
}

// 辅助函数
function getSleepQualityText(rating) {
    const texts = ['', '😴 很差', '😐 一般', '😊 不错', '😄 很好', '😁 完美'];
    return texts[parseInt(rating) || 3];
}

function getSleepStageText(hours, type) {
    if (!hours) return '-';
    const val = parseFloat(hours);
    if (type === 'deep') {
        if (val >= 2) return '✅ 良好';
        if (val >= 1.5) return '👌 正常';
        return '⚠️ 偏短';
    }
    if (type === 'rem') {
        if (val >= 1.5 && val <= 2.5) return '✅ 正常';
        if (val < 1.5) return '⚠️ 偏短';
        return '⚠️ 偏长';
    }
    return '-';
}

function getRHRText(rhr) {
    if (!rhr) return '-';
    const val = parseInt(rhr);
    if (val < 55) return '✅ 优秀';
    if (val < 60) return '👌 正常';
    if (val < 70) return '⚠️ 偏高';
    return '⚠️ 高';
}

function getScoreText(score) {
    if (score >= 90) return '优秀🌟';
    if (score >= 80) return '良好✅';
    if (score >= 70) return '及格👌';
    if (score >= 60) return '加油💪';
    return '需改进⚠️';
}

function isMonday(dateStr) {
    const date = new Date(dateStr);
    return date.getDay() === 1;
}

// HTTP 服务器
const server = http.createServer((req, res) => {
    // CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // 表单页面
    if (req.method === 'GET' && req.url === '/') {
        const htmlPath = path.join(WORKSPACE, 'health-form/index.html');
        if (fs.existsSync(htmlPath)) {
            const html = fs.readFileSync(htmlPath, 'utf8');
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
            res.end(html);
        } else {
            res.writeHead(404);
            res.end('页面不存在');
        }
        return;
    }
    
    // Strava 数据 API
    if (req.method === 'GET' && req.url === '/api/strava/today') {
        try {
            const stravaFile = path.join(WORKSPACE, 'data/strava/latest-activities.json');
            const today = new Date().toISOString().split('T')[0];
            
            if (!fs.existsSync(stravaFile)) {
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ found: false, message: '无 Strava 数据' }));
                return;
            }
            
            const activities = JSON.parse(fs.readFileSync(stravaFile, 'utf8'));
            const todayActivity = activities.find(act => {
                const startDate = act.start_date_local.split('T')[0];
                return startDate === today;
            });
            
            if (todayActivity) {
                const result = {
                    found: true,
                    name: todayActivity.name,
                    type: todayActivity.sport_type || todayActivity.type,
                    distance: (todayActivity.distance / 1000).toFixed(2),
                    duration: Math.round(todayActivity.moving_time / 60),
                    date: todayActivity.start_date_local
                };
                log(`🏃 Strava 今日数据：${result.name} (${result.distance}km, ${result.duration}分钟)`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(result));
            } else {
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ found: false, message: '今天暂无 Strava 记录' }));
            }
        } catch (e) {
            log(`❌ Strava API 错误：${e.message}`);
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: e.message }));
        }
        return;
    }
    
    // 提交数据
    if (req.method === 'POST' && req.url === '/submit') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                log(`收到表单提交：${JSON.stringify(data)}`);
                
                const date = data.date || new Date().toISOString().split('T')[0];
                const { scores, suggestions, sleepDuration, totalSleepStages } = updateStatsFile(data, date);
                sendFeishuConfirmation(data, date, scores, suggestions, sleepDuration, totalSleepStages);
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, message: '提交成功' }));
            } catch (e) {
                log(`解析错误：${e.message}`);
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: false, error: e.message }));
            }
        });
        return;
    }
    
    // 其他请求
    res.writeHead(404);
    res.end('Not Found');
});

// 启动时自动同步 Strava 数据
function syncStravaOnStartup() {
    log('🔄 启动时同步 Strava 数据...');
    try {
        const { execSync } = require('child_process');
        const result = execSync('cd /Users/liwang/.openclaw/workspace && ./scripts/sync-strava-data.sh 2>&1', { encoding: 'utf8' });
        log('✅ Strava 同步完成:\\n' + result.split('\\n').slice(-5).join('\\n'));
    } catch (e) {
        log('⚠️ Strava 同步失败：' + e.message);
    }
}

server.listen(PORT, '0.0.0.0', () => {
    log(`🚀 健康堡表单服务器启动在端口 ${PORT}`);
    log(`📝 表单地址：http://0.0.0.0:${PORT}/`);
    log(`📊 提交地址：http://0.0.0.0:${PORT}/submit`);
    
    // 获取本机 IP
    const os = require('os');
    const interfaces = os.networkInterfaces();
    let localIp = 'localhost';
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                localIp = iface.address;
                break;
            }
        }
        if (localIp !== 'localhost') break;
    }
    log(`🌐 局域网访问地址：http://${localIp}:${PORT}/`);
    
    // 启动时同步 Strava
    syncStravaOnStartup();
});
