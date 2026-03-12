#!/usr/bin/env node
/**
 * 关系堡每周问卷服务器
 * 接收关系数据，计算评分，保存到数据档案，发送飞书确认
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.PORT || 8899;
const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const STATS_DIR = path.join(WORKSPACE, 'daily-output/relationship/weekly-stats');
const LOG_PATH = path.join(WORKSPACE, 'logs/relationship-form.log');

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(LOG_PATH, logLine);
    console.log(logLine.trim());
}

/**
 * 计算关系堡评分
 */
function calculateScores(data) {
    const scores = {
        love: 0,
        family: 0,
        social: 0,
        overall: 0
    };
    
    // 爱情关系评分（如有）
    if (data.love_intimacy) {
        const loveAvg = (
            parseInt(data.love_intimacy) +
            parseInt(data.love_communication) +
            parseInt(data.love_support) +
            parseInt(data.love_trust)
        ) / 4;
        scores.love = Math.round(loveAvg * 10);
    } else {
        scores.love = 0; // 无爱情关系
    }
    
    // 家庭关系评分
    const familyGatherings = parseInt(data.family_gatherings) || 0;
    const familyCommHours = parseFloat(data.family_communication_hours) || 0;
    const familySatisfaction = parseInt(data.family_satisfaction) || 5;
    
    scores.family = Math.round((
        (familyGatherings >= 1 ? 30 : familyGatherings * 30) +
        (familyCommHours >= 5 ? 40 : (familyCommHours / 5) * 40) +
        (familySatisfaction * 3)
    ));
    
    // 社交关系评分
    const newFriends = parseInt(data.social_new_friends) || 0;
    const oldFriendsContact = parseInt(data.social_old_friends_contact) || 0;
    const socialEvents = parseInt(data.social_events) || 0;
    const socialEnergy = parseInt(data.social_energy) || 5;
    
    scores.social = Math.round((
        (newFriends >= 1 ? 20 : newFriends * 20) +
        (oldFriendsContact >= 3 ? 30 : (oldFriendsContact / 3) * 30) +
        (socialEvents >= 1 ? 20 : socialEvents * 20) +
        (socialEnergy * 3)
    ));
    
    // 总体满意度
    scores.overall = parseInt(data.overall_satisfaction) * 10 || 50;
    
    // 综合评分（平均）
    scores.total = Math.round((scores.love + scores.family + scores.social + scores.overall) / 4);
    
    return scores;
}

/**
 * 生成建议
 */
function generateSuggestions(data, scores) {
    const suggestions = [];
    
    // 爱情关系建议
    if (scores.love > 0) {
        if (scores.love >= 80) {
            suggestions.push('💕 爱情关系状态优秀，继续保持！');
        } else if (scores.love >= 60) {
            suggestions.push('💕 爱情关系良好，可以尝试增加深度沟通');
        } else {
            suggestions.push('💕 爱情关系需要关注，建议安排一次深度沟通');
        }
    }
    
    // 家庭关系建议
    if (scores.family >= 80) {
        suggestions.push('👨‍👩‍👦 家庭关系和谐，继续保持定期聚会');
    } else if (scores.family >= 60) {
        suggestions.push('👨‍👩‍👦 家庭关系良好，可以增加共同活动');
    } else {
        suggestions.push('👨‍👩‍👦 建议增加与家人的沟通时间和活动');
    }
    
    // 社交关系建议
    if (scores.social >= 80) {
        suggestions.push('🤝 社交活跃，能量充足！');
    } else if (scores.social >= 60) {
        suggestions.push('🤝 社交状态良好，保持适度社交');
    } else {
        suggestions.push('🤝 建议增加社交活动，但注意不要过度消耗能量');
    }
    
    // 基于亮点和问题的建议
    if (data.love_issues && data.love_issues.trim()) {
        suggestions.push('💡 记录的关系问题建议及时解决，避免积累');
    }
    
    return suggestions;
}

/**
 * 更新统计文件
 */
function updateStatsFile(data, date) {
    const statsFile = path.join(STATS_DIR, `${date}-relationship-stats.md`);
    
    // 确保目录存在
    if (!fs.existsSync(STATS_DIR)) {
        fs.mkdirSync(STATS_DIR, { recursive: true });
    }
    
    const scores = calculateScores(data);
    const suggestions = generateSuggestions(data, scores);
    
    // 计算周数
    const startDate = new Date('2026-03-10');
    const currentDate = new Date(date);
    const daysElapsed = Math.floor((currentDate - startDate) / (1000 * 60 * 60 * 24));
    const weekNum = Math.floor(daysElapsed / 7) + 1;
    
    // 生成 Markdown 内容
    const content = `---
type: relationship-weekly-stats
date: ${date}
week: ${weekNum}
agent: relationship-castle
version: v1.0
data_sources:
  - 用户问卷：relationship-form 表单提交
---

# 💕 关系堡每周统计 | ${date}

**生成时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}  
**12 周计划：** 第 ${weekNum}周  
**数据完整度：** ✅ 已完整  
**状态：** ✅ 数据已完整

---

## 💕 爱情关系

| 维度 | 评分 | 满分 |
|------|------|------|
| 亲密感 | ${data.love_intimacy || 0}/10 | 10 |
| 沟通舒适度 | ${data.love_communication || 0}/10 | 10 |
| 情感支持度 | ${data.love_support || 0}/10 | 10 |
| 信任感 | ${data.love_trust || 0}/10 | 10 |
| **爱情关系评分** | **${scores.love}/100** | 100 |

**本周亮点：**
${data.love_highlights && data.love_highlights.trim() ? data.love_highlights : '无'}

**需要改善的问题：**
${data.love_issues && data.love_issues.trim() ? data.love_issues : '无'}

---

## 👨‍👩‍👦 家庭关系

| 指标 | 数值 | 评估 |
|------|------|------|
| 家庭聚会次数 | ${data.family_gatherings || 0}次 | ${parseInt(data.family_gatherings) >= 1 ? '✅' : '⏳'} |
| 沟通时长 | ${data.family_communication_hours || 0}小时 | ${parseFloat(data.family_communication_hours) >= 5 ? '✅' : '⏳'} |
| 活动满意度 | ${data.family_satisfaction || 0}/10 | ${parseInt(data.family_satisfaction) >= 7 ? '✅' : '⏳'} |
| **家庭关系评分** | **${scores.family}/100** | 100 |

---

## 🤝 社交关系

| 指标 | 数值 | 评估 |
|------|------|------|
| 新朋友结识 | ${data.social_new_friends || 0}人 | - |
| 老友联系 | ${data.social_old_friends_contact || 0}次 | ${parseInt(data.social_old_friends_contact) >= 3 ? '✅' : '⏳'} |
| 社交活动 | ${data.social_events || 0}次 | ${parseInt(data.social_events) >= 1 ? '✅' : '⏳'} |
| 社交能量 | ${data.social_energy || 0}/10 | ${parseInt(data.social_energy) >= 7 ? '✅' : '⏳'} |
| **社交关系评分** | **${scores.social}/100** | 100 |

---

## 📊 本周评分

| 维度 | 评分 | 满分 | 完成度 | 说明 |
|------|------|------|--------|------|
| 爱情关系 | ${scores.love}/100 | 100 | ${scores.love}% | ${scores.love >= 80 ? '优秀' : scores.love >= 60 ? '良好' : '需改善'} |
| 家庭关系 | ${scores.family}/100 | 100 | ${scores.family}% | ${scores.family >= 80 ? '优秀' : scores.family >= 60 ? '良好' : '需改善'} |
| 社交关系 | ${scores.social}/100 | 100 | ${scores.social}% | ${scores.social >= 80 ? '优秀' : scores.social >= 60 ? '良好' : '需改善'} |
| 整体满意度 | ${scores.overall}/100 | 100 | ${scores.overall}% | - |
| **综合评分** | **${scores.total}/100** | **100** | **${scores.total}%** | **${scores.total >= 80 ? '优秀🌟' : scores.total >= 60 ? '良好✅' : '加油💪'}** |

---

## 💡 本周关系总结

**最大的关系收获：**
${data.weekly_gains && data.weekly_gains.trim() ? data.weekly_gains : '无'}

**下周关系目标：**
${data.next_week_goals && data.next_week_goals.trim() ? data.next_week_goals : '无'}

---

## 💡 明日建议

${suggestions.map(s => s).join('\n\n')}

---

## 📈 累计数据

⏳ 累计数据待汇总...

---

💕 城堡关系堡 | 用心经营，关系和谐！
`;

    fs.writeFileSync(statsFile, content, 'utf8');
    log(`✅ 统计文件已更新：${statsFile}`);
    
    return { scores, suggestions };
}

/**
 * 发送飞书确认消息
 */
function sendFeishuConfirmation(data, date, scores, suggestions) {
    const weekNum = Math.floor((new Date(date) - new Date('2026-03-10')) / (1000 * 60 * 60 * 24) / 7) + 1;
    
    const message = `💕 **关系堡每周复盘 | 第${weekNum}周**

**提交时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}

---

**📊 本周评分：**

| 维度 | 评分 | 状态 |
|------|------|------|
| 💕 爱情关系 | ${scores.love}/100 | ${scores.love >= 80 ? '🌟优秀' : scores.love >= 60 ? '✅良好' : '💪需改善'} |
| 👨‍👩‍👦 家庭关系 | ${scores.family}/100 | ${scores.family >= 80 ? '🌟优秀' : scores.family >= 60 ? '✅良好' : '💪需改善'} |
| 🤝 社交关系 | ${scores.social}/100 | ${scores.social >= 80 ? '🌟优秀' : scores.social >= 60 ? '✅良好' : '💪需改善'} |
| **综合评分** | **${scores.total}/100** | **${scores.total >= 80 ? '🌟优秀' : scores.total >= 60 ? '✅良好' : '💪需改善'}** |

---

**💡 建议：**
${suggestions.map(s => '• ' + s).join('\n')}

---

**📝 数据已保存到：**
\`daily-output/relationship/weekly-stats/${date}-relationship-stats.md\`

---

💕 城堡关系堡 | 用心经营，关系和谐！
`;

    try {
        const result = execSync(`/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "${message.replace(/"/g, '\\"')}"`, {
            encoding: 'utf8',
            cwd: WORKSPACE
        });
        log(`✅ 飞书确认消息已发送`);
    } catch (error) {
        log(`❌ 飞书消息发送失败：${error.message}`);
    }
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
        const htmlPath = path.join(WORKSPACE, 'relationship-form/index.html');
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
                log(`收到关系问卷提交：${JSON.stringify(data)}`);
                
                const date = data.date || new Date().toISOString().split('T')[0];
                const { scores, suggestions } = updateStatsFile(data, date);
                sendFeishuConfirmation(data, date, scores, suggestions);
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, scores: scores }));
            } catch (error) {
                log(`❌ 处理提交失败：${error.message}`);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: false, message: error.message }));
            }
        });
        return;
    }
    
    // 404
    res.writeHead(404);
    res.end('Not Found');
});

server.listen(PORT, '0.0.0.0', () => {
    log(`🚀 关系堡表单服务器启动在端口 ${PORT}`);
    log(`📝 表单地址：http://0.0.0.0:${PORT}/`);
    log(`📊 提交地址：http://0.0.0.0:${PORT}/submit`);
    
    // 获取局域网 IP
    const os = require('os');
    const interfaces = os.networkInterfaces();
    let localIP = 'localhost';
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                localIP = iface.address;
                break;
            }
        }
    }
    log(`🌐 局域网访问地址：http://${localIP}:${PORT}/`);
});
