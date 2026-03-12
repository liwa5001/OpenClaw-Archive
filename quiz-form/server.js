#!/usr/bin/env node
/**
 * 成长堡每日考题表单服务器
 * 接收考题答案，评分，保存到学习档案，发送飞书确认
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.PORT || 8898;
const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const QUIZ_DIR = path.join(WORKSPACE, 'daily-output/growth/quiz-scores');
const LOG_PATH = path.join(WORKSPACE, 'logs/quiz-form.log');

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(LOG_PATH, logLine);
    console.log(logLine.trim());
}

// 正确答案（根据周数可以动态加载）
const CORRECT_ANSWERS = {
    q1: 'A',  // Gateway、Agent、Skills
    q2: 'A',  // 角色 + 任务 + 约束 + 示例
    q3: 'B'   // 执行独立的子任务
};

/**
 * 评分
 */
function calculateScore(data) {
    let score = 0;
    const totalQuestions = 3;
    const pointsPerQuestion = 100 / totalQuestions;
    
    if (data.q1 === CORRECT_ANSWERS.q1) score += pointsPerQuestion;
    if (data.q2 === CORRECT_ANSWERS.q2) score += pointsPerQuestion;
    if (data.q3 === CORRECT_ANSWERS.q3) score += pointsPerQuestion;
    
    return Math.round(score);
}

/**
 * 保存考题答案和分数
 */
function saveQuizResult(data, score, date) {
    const resultFile = path.join(QUIZ_DIR, `${date}-quiz-result.md`);
    
    // 确保目录存在
    if (!fs.existsSync(QUIZ_DIR)) {
        fs.mkdirSync(QUIZ_DIR, { recursive: true });
    }
    
    // 计算正确率
    const correctCount = [data.q1, data.q2, data.q3].filter((a, i) => 
        a === CORRECT_ANSWERS[`q${i+1}`]
    ).length;
    
    const content = `---
type: growth-quiz-result
date: ${date}
agent: growth-castle
version: v2.0
data_sources:
  - 用户问卷：quiz-form 表单提交（选择题）
---

# 📚 成长堡每日考题结果 | ${date}

**提交时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}  
**得分：** ${score}/100  
**正确率：** ${correctCount}/3 (${Math.round((correctCount/3)*100)}%)

---

## 📝 答题详情

| 题号 | 你的答案 | 正确答案 | 结果 |
|------|---------|---------|------|
| 考题 1 | ${data.q1 || '未答'} | ${CORRECT_ANSWERS.q1} | ${data.q1 === CORRECT_ANSWERS.q1 ? '✅' : '❌'} |
| 考题 2 | ${data.q2 || '未答'} | ${CORRECT_ANSWERS.q2} | ${data.q2 === CORRECT_ANSWERS.q2 ? '✅' : '❌'} |
| 考题 3 | ${data.q3 || '未答'} | ${CORRECT_ANSWERS.q3} | ${data.q3 === CORRECT_ANSWERS.q3 ? '✅' : '❌'} |

---

## 📊 分数记录

**本次得分：** ${score}/100

**用途：**
- 每日学习质量评估
- 周度学习趋势分析
- 月度/季度报告生成
- 学习效果长期追踪

---

## 📈 累计数据

⏳ 累计数据待汇总...

---

🏰 城堡成长堡 | 持续学习，日拱一卒！📚
`;

    fs.writeFileSync(resultFile, content, 'utf8');
    log(`✅ 考题结果已保存：${resultFile}`);
    
    // 更新累计数据文件
    updateCumulativeData(date, score);
    
    return resultFile;
}

/**
 * 更新累计数据
 */
function updateCumulativeData(date, score) {
    const cumulativeFile = path.join(QUIZ_DIR, 'cumulative-scores.md');
    
    let cumulativeData = {
        totalQuizzes: 0,
        totalScore: 0,
        averageScore: 0,
        scores: []
    };
    
    // 读取现有数据
    if (fs.existsSync(cumulativeFile)) {
        try {
            const content = fs.readFileSync(cumulativeFile, 'utf8');
            const jsonMatch = content.match(/```json\n([\s\S]*?)\n```/);
            if (jsonMatch) {
                cumulativeData = JSON.parse(jsonMatch[1]);
            }
        } catch (e) {
            log(`⚠️ 读取累计数据失败：${e.message}`);
        }
    }
    
    // 添加新数据
    cumulativeData.scores.push({ date, score });
    cumulativeData.totalQuizzes += 1;
    cumulativeData.totalScore += score;
    cumulativeData.averageScore = Math.round(cumulativeData.totalScore / cumulativeData.totalQuizzes);
    
    // 生成 Markdown
    const markdown = `# 📊 成长堡考题累计数据

**最后更新：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}

## 📈 统计数据

| 指标 | 数值 |
|------|------|
| 总考题次数 | ${cumulativeData.totalQuizzes} |
| 总分 | ${cumulativeData.totalScore} |
| 平均分 | ${cumulativeData.averageScore} |

## 📋 详细记录

\`\`\`json
${JSON.stringify(cumulativeData, null, 2)}
\`\`\`

---
🏰 城堡成长堡 | 数据驱动学习进步！
`;

    fs.writeFileSync(cumulativeFile, markdown, 'utf8');
    log(`✅ 累计数据已更新`);
}

/**
 * 发送飞书确认消息
 */
function sendFeishuConfirmation(data, date, score, resultFile) {
    const correctCount = [data.q1, data.q2, data.q3].filter((a, i) => 
        a === CORRECT_ANSWERS[`q${i+1}`]
    ).length;
    
    let feedback = '';
    if (score >= 90) {
        feedback = '🌟 太棒了！完全掌握！';
    } else if (score >= 70) {
        feedback = '✅ 不错！继续巩固！';
    } else if (score >= 60) {
        feedback = '👌 及格！还有提升空间！';
    } else {
        feedback = '💪 加油！建议复习后再试！';
    }
    
    const message = `📚 **成长堡考题答案已提交 | ${date}**

**提交时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}

---

**📊 答题情况：**
- ✅ 正确题目：${correctCount}/3
- 📈 得分：**${score}/100**
- 💬 评估：${feedback}

**📝 答案详情：**
| 题号 | 你的答案 | 正确答案 |
|------|---------|---------|
| 考题 1 | ${data.q1 || '未答'} | ${CORRECT_ANSWERS.q1} |
| 考题 2 | ${data.q2 || '未答'} | ${CORRECT_ANSWERS.q2} |
| 考题 3 | ${data.q3 || '未答'} | ${CORRECT_ANSWERS.q3} |

---

**📈 数据记录：**
- 结果已保存到：\`${resultFile}\`
- 分数将用于月度/季度报告分析
- 累计数据自动更新

---

🏰 城堡成长堡 | 持续学习，日拱一卒！
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
        const htmlPath = path.join(WORKSPACE, 'quiz-form/index.html');
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
                log(`收到考题提交：${JSON.stringify(data)}`);
                
                const date = data.date || new Date().toISOString().split('T')[0];
                const score = calculateScore(data);
                const resultFile = saveQuizResult(data, score, date);
                sendFeishuConfirmation(data, date, score, resultFile);
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, score: score, message: '提交成功' }));
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
    log(`🚀 成长堡考题服务器启动在端口 ${PORT}`);
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
