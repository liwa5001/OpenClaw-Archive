#!/usr/bin/env node
/**
 * NLP 情感分析模块
 * 使用 Hugging Face Transformers 进行中文情感分析
 */

// 注意：需要先安装 @xenova/transformers
// npm install @xenova/transformers

const { pipeline } = require('@xenova/transformers');
const fs = require('fs');
const path = require('path');

const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const NLP_LOG_PATH = path.join(WORKSPACE, 'logs/nlp-analysis.log');

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(NLP_LOG_PATH, logLine);
    console.log(logLine.trim());
}

/**
 * 情感分析器类
 */
class SentimentAnalyzer {
    constructor() {
        this.analyzer = null;
        this.initialized = false;
    }

    /**
     * 初始化模型
     */
    async initialize() {
        if (this.initialized) return;

        log('正在加载 NLP 情感分析模型...');
        
        try {
            // 使用中文情感分析模型
            this.analyzer = await pipeline('sentiment-analysis', 'Xenova/bert-base-chinese');
            this.initialized = true;
            log('✅ NLP 模型加载完成');
        } catch (error) {
            log(`❌ 模型加载失败：${error.message}`);
            throw error;
        }
    }

    /**
     * 分析文本情感
     * @param {string} text - 要分析的文本
     * @returns {Promise<Object>} - 情感分析结果
     */
    async analyze(text) {
        if (!this.initialized) {
            await this.initialize();
        }

        try {
            const result = await this.analyzer(text);
            
            // 标准化结果
            const sentiment = result[0];
            const score = sentiment.score;
            const label = sentiment.label;

            // 转换为 -1 到 +1 的情感得分
            const normalizedScore = label === 'POSITIVE' ? score : -score;

            return {
                original: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
                sentiment: label,
                score: normalizedScore,
                confidence: score,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            log(`❌ 情感分析失败：${error.message}`);
            return {
                original: text.substring(0, 50),
                sentiment: 'NEUTRAL',
                score: 0,
                confidence: 0,
                error: error.message
            };
        }
    }

    /**
     * 批量分析聊天记录
     * @param {Array<string>} messages - 消息数组
     * @returns {Promise<Object>} - 汇总分析结果
     */
    async analyzeChat(messages) {
        log(`开始分析 ${messages.length} 条消息...`);

        const results = [];
        let positiveCount = 0;
        let negativeCount = 0;
        let neutralCount = 0;
        let totalScore = 0;

        for (const msg of messages) {
            const result = await this.analyze(msg);
            results.push(result);

            if (result.sentiment === 'POSITIVE') positiveCount++;
            else if (result.sentiment === 'NEGATIVE') negativeCount++;
            else neutralCount++;

            totalScore += result.score;
        }

        const avgScore = totalScore / messages.length;

        // 情感分布
        const distribution = {
            positive: positiveCount,
            negative: negativeCount,
            neutral: neutralCount,
            positiveRatio: positiveCount / messages.length,
            negativeRatio: negativeCount / messages.length,
            neutralRatio: neutralCount / messages.length
        };

        // 情感健康指数（0-100）
        const healthIndex = Math.round((avgScore + 1) * 50);

        // 冲突检测
        const conflictDetected = negativeCount > messages.length * 0.3;

        return {
            totalMessages: messages.length,
            distribution,
            avgScore,
            healthIndex,
            conflictDetected,
            results,
            timestamp: new Date().toISOString()
        };
    }

    /**
     * 提取关键词
     * @param {string} text - 文本
     * @returns {Array<string>} - 关键词数组
     */
    extractKeywords(text) {
        // 简单的中文分词和关键词提取
        // 实际应用中应该使用更好的中文分词库（如 node-segmentit）
        const stopwords = ['的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个'];
        
        // 简单分词（按字符）
        const words = text.split(/[，。！？、；：""''\s]+/);
        
        // 过滤停用词和短词
        const keywords = words
            .filter(word => word.length > 1 && !stopwords.includes(word))
            .slice(0, 20); // 最多 20 个关键词

        return keywords;
    }

    /**
     * 生成情感报告
     * @param {Object} analysisResult - 分析结果
     * @param {string} date - 日期
     * @returns {string} - Markdown 格式报告
     */
    generateReport(analysisResult, date) {
        const { distribution, avgScore, healthIndex, conflictDetected, totalMessages } = analysisResult;

        let report = `# 💕 关系情感分析报告 | ${date}

**分析时间：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}
**消息总数：** ${totalMessages} 条

---

## 📊 情感分布

| 情感类型 | 数量 | 占比 |
|---------|------|------|
| 😊 正面 | ${distribution.positive} | ${(distribution.positiveRatio * 100).toFixed(1)}% |
| 😔 负面 | ${distribution.negative} | ${(distribution.negativeRatio * 100).toFixed(1)}% |
| 😐 中性 | ${distribution.neutral} | ${(distribution.neutralRatio * 100).toFixed(1)}% |

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

        return report;
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
