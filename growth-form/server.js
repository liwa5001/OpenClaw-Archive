#!/usr/bin/env node
/**
 * 成长堡问卷表单服务器
 * 接收表单提交，解析数据，更新统计文件，发送飞书确认
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.PORT || 8896;
const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const STATS_DIR = path.join(WORKSPACE, 'daily-output/growth/daily-stats');
const LOG_PATH = path.join(WORKSPACE, 'logs/growth-form.log');

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
        study: 0,
        quality: 0,
        output: 0,
        total: 0
    };
    
    // 学习时长评分（50 分）- 基于 90 分钟目标
    const totalDuration = parseInt(data.total_duration) || 0;
    if (totalDuration >= 90) {
        scores.study = 50;
    } else {
        scores.study = Math.round((totalDuration / 90) * 50);
    }
    
    // 质量评分（30 分）
    const qualityRating = parseInt(data.quality_rating) || 3;
    scores.quality = qualityRating * 6;
    
    // 保存 qualityRating 供后续使用
    this.qualityRating = qualityRating;
    
    // 产出评分（20 分）
    let outputCount = 0;
    if (data.output_notes && parseInt(data.output_notes) > 0) outputCount++;
    if (data.output_practice && parseInt(data.output_practice) > 0) outputCount++;
    if (data.output_projects && parseInt(data.output_projects) > 0) outputCount++;
    scores.output = Math.round(outputCount / 3 * 20);
    
    scores.total = scores.study + scores.quality + scores.output;
    
    return scores;
}

/**
 * 生成建议
 */
function generateSuggestions(data, scores) {
    const suggestions = [];
    
    // 学习时长建议
    const totalDuration = parseInt(data.total_duration) || 0;
    if (totalDuration < 90) {
        suggestions.push(`📚 今日学习 ${totalDuration}分钟，建议达到 90 分钟目标`);
    } else {
        suggestions.push('📚 学习时长达标，继续保持！');
    }
    
    // 质量建议
    const qualityRating = parseInt(data.quality_rating) || 3;
    if (qualityRating < 3) {
        suggestions.push('⭐ 学习质量一般，尝试调整学习方法或环境');
    } else if (qualityRating >= 4) {
        suggestions.push('⭐ 学习质量很好，保持专注！');
    }
    
    // 产出建议
    if (!data.output_notes || parseInt(data.output_notes) === 0) {
        suggestions.push('📝 建议做学习笔记，帮助巩固知识');
    }
    if (!data.output_practice || parseInt(data.output_practice) === 0) {
        suggestions.push('💻 建议增加实操练习，学以致用');
    }
    
    // 问题跟进
    if (data.problems && data.problems.trim() && data.problems.trim() !== '无') {
        suggestions.push('💡 遇到的问题已记录，建议及时解决或寻求帮助');
    }
    
    return suggestions;
}

/**
 * 更新统计文件
 */
function updateStatsFile(data, date) {
    const statsFile = path.join(STATS_DIR, `${date}-growth-stats.md`);
    
    // 确保目录存在
    if (!fs.existsSync(STATS_DIR)) {
        fs.mkdirSync(STATS_DIR, { recursive: true });
    }
    
    const scores = calculateScores(data);
    const suggestions = generateSuggestions(data, scores);
    
    // 获取质量评分
    const qualityRating = parseInt(data.quality_rating) || 3;
    
    // 计算各方向占比
    const oc = parseInt(data.oc_duration) || 0;
    const claude = parseInt(data.claude_duration) || 0;
    const video = parseInt(data.video_duration) || 0;
    const total = oc + claude + video;
    
    const ocPercent = total > 0 ? Math.round((oc / total) * 100) : 0;
    const claudePercent = total > 0 ? Math.round((claude / total) * 100) : 0;
    const videoPercent = total > 0 ? Math.round((video / total) * 100) : 0;
    
    // 生成 Markdown 内容
    const content = `---
type: growth-daily-stats
date: ${date}
week: ${data.week_num || 1}
day: ${data.day_in_week || 1}
agent: growth-castle
version: v1.0
data_sources:
  - 用户问卷：growth-form 表单提交
  - 12 周计划：goals/growth-12week-plan-detailed.md
---

# 📚 成长堡每日统计 | ${date}

**生成时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}  
**12 周计划：** 第 ${data.week_num || 1}周 第${data.day_in_week || 1}天  
**数据完整度：** ✅ 已完整  
**状态：** ✅ 数据已完整

---

## 📖 今日学习

| 方向 | 时长 | 内容 | 占比 |
|------|------|------|------|
| 🏰 OpenClaw | ${oc}分钟 | ${data.oc_content || '-'} | ${ocPercent}% |
| 🤖 Claude AI | ${claude}分钟 | ${data.claude_content || '-'} | ${claudePercent}% |
| 🎬 视频制作 | ${video}分钟 | ${data.video_content || '-'} | ${videoPercent}% |
| **总计** | **${total}分钟** | - | **100%** |

**日目标：** 90 分钟 ${total >= 90 ? '✅' : '⏳'}  
**周目标：** 630 分钟

---

## ⭐ 学习质量

| 指标 | 数值 | 评估 |
|------|------|------|
| 质量评分 | ${qualityRating}/5 | ${getQualityText(data.quality_rating)} |
| 学习笔记 | ${data.output_notes || 0}页 | - |
| 实操练习 | ${data.output_practice || 0}次 | - |
| 作品/代码 | ${data.output_projects || 0}个 | - |

---

## 📊 今日评分

| 维度 | 评分 | 满分 | 完成度 | 说明 |
|------|------|------|--------|------|
| 学习时长 | ${scores.study}/50 | 50 | ${Math.round(scores.study*2)}% | ${total}分钟 |
| 学习质量 | ${scores.quality}/30 | 30 | ${Math.round(scores.quality*3.33)}% | ${data.quality_rating}/5 分 |
| 产出成果 | ${scores.output}/20 | 20 | ${Math.round(scores.output*5)}% | 基于产出 |
| **综合评分** | **${scores.total}/100** | **100** | **${scores.total}%** | **${getScoreText(scores.total)}** |

---

## 📋 考题记录

**考题内容：**
${data.exam_question && data.exam_question.trim() ? data.exam_question : '无'}

**考试成绩：** ${data.exam_score && data.exam_score.trim() ? data.exam_score : '-'}

---

## 💡 问题与计划

**遇到的问题：**
${data.problems && data.problems.trim() ? data.problems : '无'}

**明日计划：**
${data.tomorrow_plan && data.tomorrow_plan.trim() ? data.tomorrow_plan : '按原计划执行'}

---

## 💡 明日建议

${suggestions.map(s => s).join('\n\n')}

---

## 📈 本周累计（W${data.week_num || 1}）

⏳ 周统计待汇总...

---

🏰 城堡成长堡 | 持续学习，日拱一卒！📚
`;

    fs.writeFileSync(statsFile, content, 'utf8');
    log(`✅ 统计文件已更新：${statsFile}`);
    
    return { scores, suggestions, totalDuration: total };
}

/**
 * 发送飞书确认消息
 */
function sendFeishuConfirmation(data, date, scores, suggestions, totalDuration) {
    const studyText = [];
    if (parseInt(data.oc_duration) > 0) studyText.push(`🏰 OpenClaw ${data.oc_duration}分钟`);
    if (parseInt(data.claude_duration) > 0) studyText.push(`🤖 Claude AI ${data.claude_duration}分钟`);
    if (parseInt(data.video_duration) > 0) studyText.push(`🎬 视频制作 ${data.video_duration}分钟`);
    
    const outputText = [];
    if (data.output_notes && parseInt(data.output_notes) > 0) outputText.push(`笔记${data.output_notes}页`);
    if (data.output_practice && parseInt(data.output_practice) > 0) outputText.push(`实操${data.output_practice}次`);
    if (data.output_projects && parseInt(data.output_projects) > 0) outputText.push(`作品${data.output_projects}个`);
    
    const message = `✅ 收到！${date} 学习复盘已记录

【学习时长】${totalDuration}分钟 ${totalDuration >= 90 ? '✅' : '⏳'}
${studyText.length > 0 ? studyText.join('\n') : '今日未学习'}

【学习质量】${data.quality_rating}/5 分 ${getQualityText(data.quality_rating)}

【今日产出】${outputText.length > 0 ? outputText.join(' | ') : '待补充'}

【问题】${data.problems && data.problems.trim() !== '无' ? data.problems : '无'}

【${data.week_num ? `第${data.week_num}周` : ''}进度】
日目标：90 分钟 ${totalDuration >= 90 ? '✅' : '⏳'}
周目标：630 分钟

【今日评分】
📚 学习：${scores.study}/50 ${scores.study >= 40 ? '✅' : '⏳'}
⭐ 质量：${scores.quality}/30 ${scores.quality >= 24 ? '✅' : '⏳'}
📝 产出：${scores.output}/20 ${scores.output >= 16 ? '✅' : '⏳'}
**综合：${scores.total}/100** ${getScoreText(scores.total)}

【明日建议】
${suggestions.join('\n')}

继续加油！💪

🏰 城堡成长堡`;

    try {
        const cmd = `/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "${message.replace(/"/g, '\\"')}"`;
        execSync(cmd, { stdio: 'pipe' });
        log('✅ 确认消息已发送（飞书）');
    } catch (e) {
        log(`❌ 发送失败：${e.message}`);
    }
}

// 辅助函数
function getQualityText(rating) {
    const texts = ['', '😴 很差', '😐 一般', '😊 不错', '😄 很好', '😁 完美'];
    return texts[parseInt(rating) || 3];
}

function getScoreText(score) {
    if (score >= 90) return '优秀🌟';
    if (score >= 80) return '良好✅';
    if (score >= 70) return '及格👌';
    if (score >= 60) return '加油💪';
    return '需改进⏳';
}

function getQuestionStatusText(status) {
    if (status === '1') return '✅ 已完成';
    if (status === '2') return '⏳ 部分完成';
    return '❌ 未开始';
}

function getVideoProgressText(progress) {
    const p = parseInt(progress) || 0;
    if (p >= 100) return '✅ 已完成';
    if (p >= 75) return '📍 75%';
    if (p >= 50) return '📍 50%';
    if (p >= 25) return '📍 25%';
    return '⏳ 未开始';
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
        const htmlPath = path.join(WORKSPACE, 'growth-form/index.html');
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
    
    // 提交数据
    if (req.method === 'POST' && req.url === '/submit') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                log(`收到表单提交：${JSON.stringify(data)}`);
                
                const date = data.date || new Date().toISOString().split('T')[0];
                const { scores, suggestions, totalDuration } = updateStatsFile(data, date);
                sendFeishuConfirmation(data, date, scores, suggestions, totalDuration);
                
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

server.listen(PORT, '0.0.0.0', () => {
    log(`🚀 成长堡表单服务器启动在端口 ${PORT}`);
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
});
