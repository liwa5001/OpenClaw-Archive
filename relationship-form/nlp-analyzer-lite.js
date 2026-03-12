#!/usr/bin/env node
/**
 * NLP 情感分析模块（轻量级中文版）
 * 使用关键词匹配 + 规则引擎，无需下载模型
 */

const fs = require('fs');
const path = require('path');

const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const NLP_LOG_PATH = path.join(WORKSPACE, 'logs/nlp-analysis.log');

function log(message) {
    const timestamp = new Date().toISOString();
    fs.appendFileSync(NLP_LOG_PATH, `[${timestamp}] ${message}\n`);
    console.log(message);
}

/**
 * 情感词典（简化版）
 */
const POSITIVE_WORDS = [
    '开心', '快乐', '高兴', '幸福', '满意', '喜欢', '爱', '好', '棒', '优秀',
    '感谢', '谢谢', '支持', '理解', '温暖', '温馨', '美好', '愉快', '舒适',
    '成功', '进步', '成长', '收获', '希望', '期待', '信心', '相信', '信任'
];

const NEGATIVE_WORDS = [
    '生气', '难过', '伤心', '痛苦', '失望', '失望', '不满', '讨厌', '恨', '差',
    '抱怨', '争吵', '冲突', '矛盾', '问题', '困难', '压力', '累', '烦',
    '失败', '退步', '失去', '绝望', '怀疑', '不信任', '背叛', '伤害'
];

const INTENSIFIERS = ['很', '非常', '特别', '极其', '太', '真', '好', '十分', '格外'];
const NEGATORS = ['不', '没', '无', '非', '未'];

/**
 * 情感分析器类
 */
class SentimentAnalyzer {
    constructor() {
        this.initialized = true;
        log('✅ 轻量级情感分析器已就绪');
    }

    /**
     * 分析文本情感
     */
    analyze(text) {
        let positiveCount = 0;
        let negativeCount = 0;

        // 直接检查文本中是否包含情感词
        POSITIVE_WORDS.forEach(word => {
            if (text.includes(word)) positiveCount++;
        });

        NEGATIVE_WORDS.forEach(word => {
            if (text.includes(word)) negativeCount++;
        });

        const total = positiveCount + negativeCount;
        const score = positiveCount - negativeCount;
        const normalizedScore = total > 0 ? score / total : 0;

        const sentiment = normalizedScore > 0.2 ? 'POSITIVE' : 
                         normalizedScore < -0.2 ? 'NEGATIVE' : 'NEUTRAL';

        return {
            original: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
            sentiment,
            score: normalizedScore,
            confidence: Math.abs(normalizedScore),
            positiveCount,
            negativeCount,
            timestamp: new Date().toISOString()
        };
    }

    /**
     * 批量分析聊天记录
     */
    analyzeChat(messages) {
        log(`开始分析 ${messages.length} 条消息...`);

        const results = [];
        let totalPositive = 0;
        let totalNegative = 0;
        let totalScore = 0;

        for (const msg of messages) {
            const result = this.analyze(msg);
            results.push(result);
            totalPositive += result.positiveCount;
            totalNegative += result.negativeCount;
            totalScore += result.score;
        }

        const avgScore = totalScore / messages.length;
        const totalWords = totalPositive + totalNegative;

        // 情感分布
        const distribution = {
            positive: results.filter(r => r.sentiment === 'POSITIVE').length,
            negative: results.filter(r => r.sentiment === 'NEGATIVE').length,
            neutral: results.filter(r => r.sentiment === 'NEUTRAL').length,
            positiveRatio: results.filter(r => r.sentiment === 'POSITIVE').length / messages.length,
            negativeRatio: results.filter(r => r.sentiment === 'NEGATIVE').length / messages.length,
            neutralRatio: results.filter(r => r.sentiment === 'NEUTRAL').length / messages.length
        };

        // 情感健康指数（0-100）
        const healthIndex = Math.round((avgScore + 1) * 50);

        // 冲突检测
        const conflictDetected = distribution.negativeRatio > 0.3;

        return {
            totalMessages: messages.length,
            distribution,
            avgScore,
            healthIndex,
            conflictDetected,
            results,
            totalPositive,
            totalNegative,
            timestamp: new Date().toISOString()
        };
    }

    /**
     * 生成情感报告
     */
    generateReport(analysisResult, date) {
        const { distribution, avgScore, healthIndex, conflictDetected, totalMessages, totalPositive, totalNegative } = analysisResult;

        return `# 💕 关系情感分析报告 | ${date}

**分析时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}
**消息总数：** ${totalMessages} 条

---

## 📊 情感分布

| 情感类型 | 数量 | 占比 |
|---------|------|------|
| 😊 正面 | ${distribution.positive} | ${(distribution.positiveRatio * 100).toFixed(1)}% |
| 😔 负面 | ${distribution.negative} | ${(distribution.negativeRatio * 100).toFixed(1)}% |
| 😐 中性 | ${distribution.neutral} | ${(distribution.neutralRatio * 100).toFixed(1)}% |

**情感词统计：** 正面 ${totalPositive} 个 | 负面 ${totalNegative} 个

---

## 📈 情感指标

**平均情感得分：** ${avgScore.toFixed(3)}（范围：-1 到 +1）

**情感健康指数：** ${healthIndex}/100
${healthIndex >= 80 ? '✅ 情感状态优秀' : healthIndex >= 60 ? '🟡 情感状态良好' : '🔴 情感状态需关注'}

**冲突预警：** ${conflictDetected ? '⚠️ 检测到较多负面情绪，建议关注' : '✅ 无明显冲突'}

---

## 💡 建议

${this.generateSuggestions(healthIndex, conflictDetected, distribution)}

---

💕 城堡关系堡 | 数据驱动关系改善
`;
    }

    /**
     * 生成建议
     */
    generateSuggestions(healthIndex, conflictDetected, distribution) {
        const suggestions = [];

        if (healthIndex >= 80) {
            suggestions.push('✅ 情感状态优秀，继续保持良好沟通！');
        } else if (healthIndex >= 60) {
            suggestions.push('🟡 情感状态良好，可以进一步优化沟通方式。');
        } else {
            suggestions.push('🔴 情感状态需要关注，建议：');
            suggestions.push('  - 增加深度沟通，表达真实感受');
            suggestions.push('  - 学习非暴力沟通技巧');
            suggestions.push('  - 必要时寻求专业咨询');
        }

        if (conflictDetected) {
            suggestions.push('\n⚠️ 检测到较多负面情绪：');
            suggestions.push('  - 冷静分析冲突原因');
            suggestions.push('  - 避免在情绪激动时做决定');
            suggestions.push('  - 尝试换位思考');
        }

        if (distribution.negativeRatio > 0.4) {
            suggestions.push('\n💡 负面情绪占比较高，建议：');
            suggestions.push('  - 记录负面情绪触发点');
            suggestions.push('  - 寻找积极的应对方式');
        }

        return suggestions.join('\n');
    }
}

// 导出模块
module.exports = { SentimentAnalyzer };

// 如果是直接运行，进行测试
if (require.main === module) {
    (async () => {
        const analyzer = new SentimentAnalyzer();
        
        // 测试文本
        const testMessages = [
            '今天和你聊天很开心',
            '我觉得我们最近沟通有点问题',
            '谢谢你一直以来的支持',
            '我有点生气，因为你没有理解我',
            '我们一起努力改善关系吧'
        ];

        log('开始测试 NLP 情感分析...');
        const result = await analyzer.analyzeChat(testMessages);
        
        console.log('\n=== 测试结果 ===');
        console.log(`消息数：${result.totalMessages}`);
        console.log(`情感健康指数：${result.healthIndex}/100`);
        console.log(`冲突检测：${result.conflictDetected ? '⚠️ 是' : '✅ 否'}`);
        console.log(`情感分布：正面 ${result.distribution.positive} | 负面 ${result.distribution.negative} | 中性 ${result.distribution.neutral}`);
        
        const report = analyzer.generateReport(result, '2026-03-12');
        console.log('\n=== 情感报告 ===');
        console.log(report);
    })();
}
