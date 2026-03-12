#!/usr/bin/env node
/**
 * Castle Six 科学综合复盘（完整版）
 * 基于木桶理论、关联分析、趋势预警、PERMA 模型进行深度分析
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const LOG_PATH = path.join(WORKSPACE, 'logs/total-review-scientific.log');

function log(message) {
    const timestamp = new Date().toISOString();
    fs.appendFileSync(LOG_PATH, `[${timestamp}] ${message}\n`);
    console.log(message);
}

/**
 * 读取城堡数据
 */
function readCastleData(castleName, date) {
    let filePath = '';
    
    if (castleName === 'health') {
        filePath = path.join(WORKSPACE, `daily-output/health/daily-stats/${date}-health-stats.md`);
    } else if (castleName === 'growth') {
        filePath = path.join(WORKSPACE, `daily-output/growth/daily-stats/${date}-growth-stats.md`);
    } else if (castleName === 'relationship') {
        filePath = path.join(WORKSPACE, `daily-output/relationship/weekly-stats/${date}-relationship-stats.md`);
    }
    
    if (!fs.existsSync(filePath)) {
        return null;
    }
    
    const content = fs.readFileSync(filePath, 'utf8');
    
    // 解析综合评分
    const scoreMatch = content.match(/\*\*综合评分\*\*\s*:\s*\*\*(\d+)\/100\*\*/);
    const score = scoreMatch ? parseInt(scoreMatch[1]) : 0;
    
    return {
        score,
        content,
        filePath
    };
}

/**
 * 读取历史数据（用于趋势分析）
 */
function readHistoricalData(castleName, days = 30) {
    const scores = [];
    const today = new Date();
    
    for (let i = 0; i < days; i++) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        const dateStr = date.toISOString().split('T')[0];
        
        const data = readCastleData(castleName, dateStr);
        if (data) {
            scores.unshift({ date: dateStr, score: data.score });
        }
    }
    
    return scores;
}

/**
 * 计算统计值
 */
function calculateStats(scores) {
    if (scores.length === 0) {
        return { mean: 0, stdDev: 0, min: 0, max: 0, minCastle: 'unknown' };
    }
    
    const validScores = scores.filter(s => s.score > 0);
    if (validScores.length === 0) {
        return { mean: 0, stdDev: 0, min: 0, max: 0, minCastle: 'unknown' };
    }
    
    const mean = Math.round(validScores.reduce((a, b) => a + b.score, 0) / validScores.length);
    const min = Math.min(...validScores.map(s => s.score));
    const max = Math.max(...validScores.map(s => s.score));
    
    // 计算标准差
    const variance = validScores.reduce((sum, s) => sum + Math.pow(s.score - mean, 2), 0) / validScores.length;
    const stdDev = Math.round(Math.sqrt(variance));
    
    // 找出最低分的城堡
    const minCastle = validScores.find(s => s.score === min)?.castle || 'unknown';
    
    return { mean, stdDev, min, max, minCastle };
}

/**
 * 趋势分析
 */
function analyzeTrend(scores) {
    if (scores.length < 3) {
        return { direction: '数据不足', change: 0 };
    }
    
    const recent = scores.slice(-3);
    const first = recent[0].score;
    const last = recent[2].score;
    const change = last - first;
    
    let direction = '稳定';
    if (change >= 10) direction = '快速上升';
    else if (change >= 5) direction = '上升';
    else if (change <= -10) direction = '快速下降';
    else if (change <= -5) direction = '下降';
    
    return { direction, change };
}

/**
 * 关联分析（简化版皮尔逊相关）
 */
function analyzeCorrelation(castle1Data, castle2Data) {
    // 简化实现：如果两个城堡分数变化方向一致，则认为正相关
    if (!castle1Data || !castle2Data || castle1Data.length < 3 || castle2Data.length < 3) {
        return { coefficient: 0, significant: false };
    }
    
    const changes1 = castle1Data.slice(1).map((d, i) => d.score - castle1Data[i].score);
    const changes2 = castle2Data.slice(1).map((d, i) => d.score - castle2Data[i].score);
    
    let sameDirection = 0;
    for (let i = 0; i < Math.min(changes1.length, changes2.length); i++) {
        if ((changes1[i] > 0 && changes2[i] > 0) || (changes1[i] < 0 && changes2[i] < 0)) {
            sameDirection++;
        }
    }
    
    const coefficient = sameDirection / Math.min(changes1.length, changes2.length);
    const significant = coefficient >= 0.6;
    
    return { coefficient: coefficient.toFixed(2), significant };
}

/**
 * 生成综合复盘报告
 */
function generateReport(data, stats, trends, correlations) {
    const today = new Date().toLocaleDateString('zh-CN', { timeZone: 'Asia/Shanghai' });
    
    // 木桶理论分析
    let bucketAnalysis = '';
    if (stats.min < 60) {
        bucketAnalysis = `🔴 **严重短板**：${getCastleName(stats.minCastle)}（${stats.min}分）需要立即关注！`;
    } else if (stats.min < 70) {
        bucketAnalysis = `🟡 **需要关注**：${getCastleName(stats.minCastle)}（${stats.min}分）有提升空间`;
    } else {
        bucketAnalysis = `✅ **无明显短板**，各堡发展均衡`;
    }
    
    // 平衡度分析
    let balanceAnalysis = '';
    if (stats.stdDev > 20) {
        balanceAnalysis = `⚠️ **严重失衡**（标准差 ${stats.stdDev}）`;
    } else if (stats.stdDev > 10) {
        balanceAnalysis = `🟡 **轻度失衡**（标准差 ${stats.stdDev}）`;
    } else {
        balanceAnalysis = `✅ **发展平衡**（标准差 ${stats.stdDev}）`;
    }
    
    // 生成建议
    const suggestions = generateSuggestions(stats.minCastle, trends, correlations);
    
    const report = `# 🏰 Castle Six 科学综合复盘

**日期：** ${today}  
**统计周期：** 过去 30 天

---

## 📊 本周总览

### 各堡得分

| 城堡 | 得分 | 状态 |
|------|------|------|
| 💪 健康堡 | ${data.health?.score || 0}/100 | ${getStatusEmoji(data.health?.score || 0)} |
| 📚 成长堡 | ${data.growth?.score || 0}/100 | ${getStatusEmoji(data.growth?.score || 0)} |
| 💕 关系堡 | ${data.relationship?.score || 0}/100 | ${getStatusEmoji(data.relationship?.score || 0)} |

### 综合评估

- **均值：** ${stats.mean} 分
- **标准差：** ${stats.stdDev}（${balanceAnalysis}）
- **短板：** ${getCastleName(stats.minCastle)}（${stats.min}分）

---

## 🔍 深度分析

### 1. 木桶理论分析

${bucketAnalysis}

**影响评估：**
- 短板限制了整体发展水平
- 建议优先改善短板堡

### 2. 平衡度分析

${balanceAnalysis}

**建议：**
${stats.stdDev < 10 ? '- ✅ 保持当前平衡状态' : 
  stats.stdDev < 20 ? '- 🟡 关注低分堡，适当调整资源分配' : 
  '- ⚠️ 需要重点调整资源分配，避免严重失衡'}

### 3. 趋势分析

| 城堡 | 趋势 | 变化 |
|------|------|------|
| 💪 健康堡 | ${trends.health?.direction || '数据不足'} | ${trends.health?.change || 0}分 |
| 📚 成长堡 | ${trends.growth?.direction || '数据不足'} | ${trends.growth?.change || 0}分 |
| 💕 关系堡 | ${trends.relationship?.direction || '数据不足'} | ${trends.relationship?.change || 0}分 |

${getTrendAnalysis(trends)}

### 4. 关联分析

| 关联对 | 相关系数 | 显著性 |
|--------|---------|--------|
| 健康 ↔ 成长 | ${correlations.healthGrowth?.coefficient || 'N/A'} | ${correlations.healthGrowth?.significant ? '✅ 显著' : '-'} |
| 健康 ↔ 关系 | ${correlations.healthRelationship?.coefficient || 'N/A'} | ${correlations.healthRelationship?.significant ? '✅ 显著' : '-'} |
| 成长 ↔ 关系 | ${correlations.growthRelationship?.coefficient || 'N/A'} | ${correlations.growthRelationship?.significant ? '✅ 显著' : '-'} |

${getCorrelationAnalysis(correlations)}

---

## 💡 专业建议

${suggestions}

---

## 📈 下周目标

| 城堡 | 当前分 | 目标分 | 关键行动 |
|------|--------|--------|---------|
| ${getCastleName(stats.minCastle)} | ${stats.min} | ${Math.min(100, stats.min + 10)} | 按上述建议执行 |
| 其他堡 | - | 保持 | 维持当前节奏 |

---

**🏰 城堡六堡 | 科学复盘，持续进步！**
`;

    return report;
}

/**
 * 获取城堡名称
 */
function getCastleName(key) {
    const names = {
        'health': '💪 健康堡',
        'growth': '📚 成长堡',
        'relationship': '💕 关系堡'
    };
    return names[key] || key;
}

/**
 * 获取状态表情
 */
function getStatusEmoji(score) {
    if (score >= 80) return '🌟';
    if (score >= 60) return '✅';
    return '💪';
}

/**
 * 生成趋势分析文字
 */
function getTrendAnalysis(trends) {
    const analysis = [];
    
    if (trends.health?.direction.includes('下降')) {
        analysis.push('⚠️ 健康堡呈下降趋势，需关注睡眠、运动、饮食');
    }
    if (trends.growth?.direction.includes('下降')) {
        analysis.push('⚠️ 成长堡呈下降趋势，需调整学习计划');
    }
    if (trends.relationship?.direction.includes('下降')) {
        analysis.push('⚠️ 关系堡呈下降趋势，需增加沟通');
    }
    
    if (analysis.length === 0) {
        return '✅ 各堡趋势稳定或上升，继续保持';
    }
    
    return analysis.join('\n');
}

/**
 * 生成关联分析文字
 */
function getCorrelationAnalysis(correlations) {
    const analysis = [];
    
    if (correlations.healthGrowth?.significant) {
        analysis.push('• 健康与成长显著正相关：健康状态好时学习效率更高');
    }
    if (correlations.healthRelationship?.significant) {
        analysis.push('• 健康与关系显著正相关：健康状态影响情绪和沟通');
    }
    if (correlations.growthRelationship?.significant) {
        analysis.push('• 成长与关系显著正相关：学习状态好时关系也更和谐');
    }
    
    if (analysis.length === 0) {
        return '⏳ 需要更多数据来进行关联分析';
    }
    
    return '发现的关联：\n' + analysis.join('\n');
}

/**
 * 生成建议
 */
function generateSuggestions(minCastle, trends, correlations) {
    const suggestions = [];
    
    // 基于短板的建议
    suggestions.push(`### 优先级 1：${getCastleName(minCastle)}改善\n`);
    
    if (minCastle === 'health') {
        suggestions.push('**具体行动：**');
        suggestions.push('- 优化睡眠质量（目标：23:00 前入睡）');
        suggestions.push('- 增加运动频率（每周 3 次，每次 30 分钟）');
        suggestions.push('- 改善饮食习惯（减少夜宵，增加蔬菜）');
        suggestions.push('\n**预期效果：** 2 周内健康堡回升 10-15 分');
    } else if (minCastle === 'growth') {
        suggestions.push('**具体行动：**');
        suggestions.push('- 调整学习计划（确保每日 90 分钟）');
        suggestions.push('- 提高学习效率（番茄工作法）');
        suggestions.push('- 坚持每日答题（巩固知识）');
        suggestions.push('\n**预期效果：** 2 周内成长堡回升 10-15 分');
    } else if (minCastle === 'relationship') {
        suggestions.push('**具体行动：**');
        suggestions.push('- 增加深度沟通（每周至少 1 次）');
        suggestions.push('- 安排优质陪伴时间（远离手机）');
        suggestions.push('- 学习非暴力沟通技巧');
        suggestions.push('\n**预期效果：** 2 周内关系堡回升 10-15 分');
    }
    
    // 基于趋势的建议
    suggestions.push('\n### 优先级 2：趋势关注\n');
    
    if (trends.health?.direction.includes('下降')) {
        suggestions.push('⚠️ 健康堡下降趋势需要立即关注');
    }
    if (trends.growth?.direction.includes('下降')) {
        suggestions.push('⚠️ 成长堡下降趋势需要调整方法');
    }
    if (trends.relationship?.direction.includes('下降')) {
        suggestions.push('⚠️ 关系堡下降趋势需要主动改善');
    }
    
    // 基于关联的建议
    if (correlations.healthGrowth?.significant || correlations.healthRelationship?.significant) {
        suggestions.push('\n### 优先级 3：关联优化\n');
        suggestions.push('💡 建议优先改善健康堡，因为健康与其他堡显著相关，健康改善会带动其他堡提升');
    }
    
    return suggestions.join('\n');
}

/**
 * 发送飞书消息
 */
function sendFeishuMessage(report) {
    const FEISHU_USER = 'ou_7781abd1e83eae23ccf01fe627f0747f';
    
    // 提取关键信息发送简短版
    const message = `🏰 **Castle Six 科学综合复盘 | ${new Date().toLocaleDateString('zh-CN')}**

完整报告已生成，包含：
- 📊 各堡得分和综合评估
- 🔍 木桶理论分析
- 📈 趋势分析
- 🔗 关联分析
- 💡 专业建议

**报告位置：**
\`agents/review-system/total-review/YYYY-MM-DD-review.md\`

---
🏰 城堡六堡 | 科学复盘，持续进步！
`;

    try {
        execSync(`/opt/homebrew/bin/openclaw message send --channel feishu --target "${FEISHU_USER}" --message "${message.replace(/"/g, '\\"')}"`, {
            encoding: 'utf8',
            cwd: WORKSPACE
        });
        log('✅ 飞书消息已发送');
    } catch (error) {
        log(`❌ 飞书消息发送失败：${error.message}`);
    }
}

/**
 * 主函数
 */
function main() {
    log('=== Castle Six 科学综合复盘开始 ===');
    
    const today = new Date().toISOString().split('T')[0];
    
    // 读取各堡数据
    const data = {
        health: readCastleData('health', today),
        growth: readCastleData('growth', today),
        relationship: readCastleData('relationship', today)
    };
    
    // 计算统计值
    const scores = [
        { castle: 'health', score: data.health?.score || 0 },
        { castle: 'growth', score: data.growth?.score || 0 },
        { castle: 'relationship', score: data.relationship?.score || 0 }
    ];
    const stats = calculateStats(scores);
    
    // 读取历史数据
    const historicalData = {
        health: readHistoricalData('health', 30),
        growth: readHistoricalData('growth', 30),
        relationship: readHistoricalData('relationship', 30)
    };
    
    // 趋势分析
    const trends = {
        health: analyzeTrend(historicalData.health),
        growth: analyzeTrend(historicalData.growth),
        relationship: analyzeTrend(historicalData.relationship)
    };
    
    // 关联分析
    const correlations = {
        healthGrowth: analyzeCorrelation(historicalData.health, historicalData.growth),
        healthRelationship: analyzeCorrelation(historicalData.health, historicalData.relationship),
        growthRelationship: analyzeCorrelation(historicalData.growth, historicalData.relationship)
    };
    
    // 生成报告
    const report = generateReport(data, stats, trends, correlations);
    
    // 保存报告
    const reportDir = path.join(WORKSPACE, 'agents/review-system/total-review');
    if (!fs.existsSync(reportDir)) {
        fs.mkdirSync(reportDir, { recursive: true });
    }
    
    const reportFile = path.join(reportDir, `${today}-review.md`);
    fs.writeFileSync(reportFile, report, 'utf8');
    log(`✅ 报告已保存：${reportFile}`);
    
    // 发送飞书消息
    sendFeishuMessage(report);
    
    log('=== Castle Six 科学综合复盘完成 ===');
}

// 运行
main();
