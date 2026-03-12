#!/usr/bin/env node
/**
 * 关系堡累计数据汇总和趋势分析
 */

const fs = require('fs');
const path = require('path');

const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const RELATIONSHIP_DIR = path.join(WORKSPACE, 'daily-output/relationship/weekly-stats');
const CUMULATIVE_FILE = path.join(RELATIONSHIP_DIR, 'cumulative-summary.md');
const LOG_PATH = path.join(WORKSPACE, 'logs/relationship-cumulative.log');

function log(message) {
    const timestamp = new Date().toISOString();
    fs.appendFileSync(LOG_PATH, `[${timestamp}] ${message}\n`);
    console.log(message);
}

/**
 * 读取所有关系堡数据
 */
function loadAllData() {
    const files = fs.readdirSync(RELATIONSHIP_DIR)
        .filter(f => f.endsWith('-relationship-stats.md') && !f.startsWith('cumulative'))
        .sort();

    const data = [];
    
    for (const file of files) {
        const filePath = path.join(RELATIONSHIP_DIR, file);
        const content = fs.readFileSync(filePath, 'utf8');
        
        // 解析 Markdown 文件
        const dateMatch = content.match(/date:\s*(\d{4}-\d{2}-\d{2})/);
        const weekMatch = content.match(/week:\s*(\d+)/);
        const totalScoreMatch = content.match(/\*\*综合评分\*\*\s*:\s*\*\*(\d+)\/100\*\*/);
        const loveScoreMatch = content.match(/爱情关系评分\s*\*\s*\*\*(\d+)\/100\*\*/);
        const familyScoreMatch = content.match(/家庭关系评分\s*\*\s*\*\*(\d+)\/100\*\*/);
        const socialScoreMatch = content.match(/社交关系评分\s*\*\s*\*\*(\d+)\/100\*\*/);
        
        if (dateMatch && totalScoreMatch) {
            data.push({
                date: dateMatch[1],
                week: weekMatch ? parseInt(weekMatch[1]) : 0,
                totalScore: parseInt(totalScoreMatch[1]),
                loveScore: loveScoreMatch ? parseInt(loveScoreMatch[1]) : 0,
                familyScore: familyScoreMatch ? parseInt(familyScoreMatch[1]) : 0,
                socialScore: socialScoreMatch ? parseInt(socialScoreMatch[1]) : 0
            });
        }
    }
    
    return data;
}

/**
 * 计算统计数据
 */
function calculateStatistics(data) {
    if (data.length === 0) {
        return {
            totalWeeks: 0,
            avgScore: 0,
            maxScore: 0,
            minScore: 0,
            trend: '无数据'
        };
    }

    const scores = data.map(d => d.totalScore);
    const totalWeeks = data.length;
    const avgScore = Math.round(scores.reduce((a, b) => a + b, 0) / totalWeeks);
    const maxScore = Math.max(...scores);
    const minScore = Math.min(...scores);

    // 趋势分析（最近 3 周）
    let trend = '稳定';
    if (data.length >= 3) {
        const recent = data.slice(-3);
        const first = recent[0].totalScore;
        const last = recent[2].totalScore;
        const change = last - first;
        
        if (change >= 10) trend = '上升 ↑↑';
        else if (change >= 5) trend = '上升 ↑';
        else if (change <= -10) trend = '下降 ↓↓';
        else if (change <= -5) trend = '下降 ↓';
        else trend = '稳定 →';
    }

    return {
        totalWeeks,
        avgScore,
        maxScore,
        minScore,
        trend,
        scores
    };
}

/**
 * 计算各维度统计
 */
function calculateDimensionStats(data) {
    const dimensions = {
        love: { name: '爱情', scores: [], avg: 0 },
        family: { name: '家庭', scores: [], avg: 0 },
        social: { name: '社交', scores: [], avg: 0 }
    };

    data.forEach(d => {
        if (d.loveScore > 0) dimensions.love.scores.push(d.loveScore);
        dimensions.family.scores.push(d.familyScore);
        dimensions.social.scores.push(d.socialScore);
    });

    // 计算平均值
    Object.keys(dimensions).forEach(key => {
        const scores = dimensions[key].scores;
        dimensions[key].avg = scores.length > 0 
            ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
            : 0;
    });

    return dimensions;
}

/**
 * 生成累计报告
 */
function generateCumulativeReport(data, stats, dimensions) {
    const today = new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' });
    
    const report = `# 💕 关系堡累计数据报告

**生成时间：** ${today}  
**统计周期：** 第 1 周 - 第${stats.totalWeeks}周

---

## 📊 总体统计

| 指标 | 数值 |
|------|------|
| 累计周数 | ${stats.totalWeeks} 周 |
| 平均综合评分 | ${stats.avgScore}/100 |
| 最高分 | ${stats.maxScore}/100 |
| 最低分 | ${stats.minScore}/100 |
| 趋势 | ${stats.trend} |

---

## 📈 各维度统计

| 维度 | 平均分 | 数据点 |
|------|--------|--------|
| 💕 爱情关系 | ${dimensions.love.avg}/100 | ${dimensions.love.scores.length} |
| 👨‍👩‍👦 家庭关系 | ${dimensions.family.avg}/100 | ${dimensions.family.scores.length} |
| 🤝 社交关系 | ${dimensions.social.avg}/100 | ${dimensions.social.scores.length} |

---

## 📉 每周得分记录

| 周数 | 日期 | 综合评分 | 爱情 | 家庭 | 社交 | 趋势 |
|------|------|---------|------|------|------|------|
${data.map((d, i) => {
    const prev = i > 0 ? data[i-1].totalScore : d.totalScore;
    const trend = d.totalScore > prev ? '↑' : d.totalScore < prev ? '↓' : '→';
    return `| 第${d.week}周 | ${d.date} | ${d.totalScore}/100 | ${d.loveScore || '-'} | ${d.familyScore} | ${d.socialScore} | ${trend} |`;
}).join('\n')}

---

## 💡 数据分析

### 优势维度
${(() => {
    const sorted = Object.entries(dimensions)
        .filter(([_, v]) => v.scores.length > 0)
        .sort(([_, a], [__, b]) => b.avg - a.avg);
    
    if (sorted.length === 0) return '暂无数据';
    
    const best = sorted[0];
    return `**${best[1].name}关系**（${best[1].avg}分）表现最佳，继续保持！`;
})()}

### 需改善维度
${(() => {
    const sorted = Object.entries(dimensions)
        .filter(([_, v]) => v.scores.length > 0)
        .sort(([_, a], [__, b]) => a.avg - b.avg);
    
    if (sorted.length === 0) return '暂无数据';
    
    const worst = sorted[0];
    return `**${worst[1].name}关系**（${worst[1].avg}分）需要更多关注和改进。`;
})()}

### 趋势分析
${stats.trend.includes('上升') ? '✅ 关系质量整体呈上升趋势，改进措施有效！' : 
  stats.trend.includes('下降') ? '⚠️ 关系质量有所下降，需要关注和调整！' : 
  '🟡 关系质量保持稳定，可以尝试进一步提升。'}

---

## 🎯 下阶段目标

基于历史数据，建议下阶段（4 周）目标：

| 维度 | 当前平均 | 目标分数 | 提升幅度 |
|------|---------|---------|---------|
| 综合评分 | ${stats.avgScore}/100 | ${Math.min(100, stats.avgScore + 10)}/100 | +10 分 |
| 💕 爱情 | ${dimensions.love.avg || 0}/100 | ${Math.min(100, (dimensions.love.avg || 0) + 10)}/100 | +10 分 |
| 👨‍👩‍👦 家庭 | ${dimensions.family.avg}/100 | ${Math.min(100, dimensions.family.avg + 10)}/100 | +10 分 |
| 🤝 社交 | ${dimensions.social.avg}/100 | ${Math.min(100, dimensions.social.avg + 10)}/100 | +10 分 |

---

## 📊 数据导出

**原始数据位置：**
\`daily-output/relationship/weekly-stats/\`

**数据格式：** Markdown

**下次更新：** 每周日 21:00（关系堡复盘后自动更新）

---

💕 城堡关系堡 | 数据驱动关系改善！
`;

    return report;
}

/**
 * 更新累计数据文件
 */
function updateCumulativeFile() {
    log('开始更新关系堡累计数据...');
    
    const data = loadAllData();
    const stats = calculateStatistics(data);
    const dimensions = calculateDimensionStats(data);
    const report = generateCumulativeReport(data, stats, dimensions);
    
    fs.writeFileSync(CUMULATIVE_FILE, report, 'utf8');
    log(`✅ 累计数据已更新：${CUMULATIVE_FILE}`);
    
    return { stats, dimensions, report };
}

// 导出模块
module.exports = { updateCumulativeFile, loadAllData, calculateStatistics };

// 如果是直接运行，执行更新
if (require.main === module) {
    updateCumulativeFile();
}
