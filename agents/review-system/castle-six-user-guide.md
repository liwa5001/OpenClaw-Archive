# 🏰 Castle Six 关系堡 + 科学总复盘使用指南

**版本：** v2.0（深度版）  
**更新日期：** 2026-03-12

---

## 📋 目录

1. [关系堡使用指南](#1-关系堡使用指南)
2. [科学总复盘堡使用指南](#2-科学总复盘堡使用指南)
3. [NLP 情感分析](#3-nlp 情感分析可选)
4. [数据位置](#4-数据位置)
5. [常见问题](#5-常见问题)

---

## 1. 关系堡使用指南

### 1.1 自动发送

**时间：** 每周日 20:00  
**渠道：** 飞书  
**内容：** 关系堡问卷链接

**消息示例：**
```
💕 关系堡每周问卷 | 第 X 周

花 5 分钟回顾本周的关系状态~

👉 http://192.168.2.58:8899/

【填写内容】
💕 爱情关系（亲密感/沟通/支持/信任）
👨‍👩‍👦 家庭关系（聚会/沟通/活动）
🤝 社交关系（新朋友/老友/活动/能量）
📊 本周总结（收获 + 目标）
```

### 1.2 填写说明

**访问链接：** http://192.168.2.58:8899/

**填写内容：**
1. **爱情关系**（如有）
   - 亲密感（1-10 分）
   - 沟通舒适度（1-10 分）
   - 情感支持度（1-10 分）
   - 信任感（1-10 分）
   - 本周亮点事件
   - 需要改善的问题

2. **家庭关系**
   - 家庭聚会次数
   - 沟通时长（小时/周）
   - 活动满意度（1-10 分）

3. **社交关系**
   - 新朋友结识数
   - 老友联系次数
   - 社交活动参与次数
   - 社交能量值（1-10 分）

4. **本周总结**
   - 整体满意度（1-10 分）
   - 最大的关系收获
   - 下周关系目标

### 1.3 提交后

- ✅ 数据保存到 `daily-output/relationship/weekly-stats/`
- ✅ 飞书收到评分和建议
- ✅ 累计数据自动更新

---

## 2. 科学总复盘堡使用指南

### 2.1 自动发送

**时间：** 每周日 21:30  
**渠道：** 飞书  
**内容：** 科学综合复盘报告

### 2.2 分析内容

**1. 木桶理论分析**
- 识别短板堡（最低分）
- 评估短板影响
- 确定优先改进目标

**2. 平衡度分析**
- 计算标准差
- 评估各堡发展平衡度
- 提供平衡建议

**3. 趋势分析**
- 30 天历史数据分析
- 上升/下降/稳定趋势
- 趋势预警

**4. 关联分析**
- 堡与堡之间的相关性
- 皮尔逊相关系数
- 因果关系推测

**5. PERMA 评估**
- 积极情绪
- 投入
- 关系
- 意义
- 成就

### 2.3 报告示例

```markdown
🏰 Castle Six 科学综合复盘

【短板识别】
🔴 严重短板：关系堡（60 分）需要立即关注！

【平衡度分析】
✅ 发展平衡（标准差 5）

【趋势分析】
健康堡：上升 ↑（+5 分）
成长堡：稳定 →（0 分）
关系堡：下降 ↓（-8 分）⚠️

【关联分析】
健康 ↔ 成长：0.67（显著正相关）
健康 ↔ 关系：0.72（显著正相关）

【专业建议】
优先级 1：关系堡改善
- 增加深度沟通
- 安排优质陪伴时间
- 学习非暴力沟通

预期效果：2 周内关系堡回升 10-15 分
```

---

## 3. NLP 情感分析（可选）

### 3.1 方案选择

**方案 A：轻量级（推荐，已内置）**
- ✅ 无需安装依赖
- ✅ 即时可用
- ✅ 基于中文情感词典
- ⚠️ 精度中等

**方案 B：深度学习（需要网络）**
- ✅ 精度高
- ❌ 需要下载模型（约 100MB）
- ❌ 需要网络连接

### 3.2 使用轻量级（默认）

**无需安装，直接使用：**
```javascript
const { SentimentAnalyzer } = require('./nlp-analyzer-lite');

const analyzer = new SentimentAnalyzer();

// 分析单条消息
const result = await analyzer.analyze('今天和你聊天很开心');
console.log(result);
// { sentiment: 'POSITIVE', score: 1, positiveCount: 1 }

// 批量分析聊天记录
const messages = [
    '今天和你聊天很开心',
    '我觉得我们最近沟通有点问题',
    '谢谢你一直以来的支持'
];

const chatResult = await analyzer.analyzeChat(messages);
console.log(`情感健康指数：${chatResult.healthIndex}/100`);
```

### 3.2 使用方法

**上传聊天记录：**
1. 将聊天记录保存为文本文件
2. 每行一条消息
3. 调用 NLP 分析器

**代码示例：**
```javascript
const { SentimentAnalyzer } = require('./nlp-analyzer');

const analyzer = new SentimentAnalyzer();

// 分析单条消息
const result = await analyzer.analyze('今天和你聊天很开心');
console.log(result);
// { sentiment: 'POSITIVE', score: 0.85, confidence: 0.85 }

// 批量分析聊天记录
const messages = [
    '今天和你聊天很开心',
    '我觉得我们最近沟通有点问题',
    '谢谢你一直以来的支持'
];

const chatResult = await analyzer.analyzeChat(messages);
console.log(chatResult);
// { healthIndex: 75, conflictDetected: false, ... }
```

### 3.3 分析报告

NLP 分析会生成：
- 情感分布（正面/负面/中性）
- 情感健康指数（0-100）
- 冲突预警
- 关键词云
- 改进建议

---

## 4. 数据位置

### 4.1 关系堡数据

```
/workspace/daily-output/relationship/weekly-stats/
├── YYYY-MM-DD-relationship-stats.md  # 每周统计数据
└── cumulative-summary.md              # 累计数据汇总
```

### 4.2 总复盘报告

```
/workspace/agents/review-system/total-review/
└── YYYY-MM-DD-review.md  # 科学综合复盘报告
```

### 4.3 NLP 分析报告（如使用）

```
/workspace/daily-output/relationship/nlp-analysis/
└── YYYY-MM-DD-nlp-report.md  # NLP 情感分析报告
```

---

## 5. 常见问题

### Q1: 关系堡问卷链接打不开？

**解决：**
1. 检查服务器是否运行：`curl http://localhost:8899/`
2. 如未运行，手动启动：
   ```bash
   cd /Users/liwang/.openclaw/workspace/relationship-form
   node server.js &
   ```

### Q2: 科学总复盘显示"数据不足"？

**原因：** 刚开始使用，没有历史数据

**解决：**
- 正常现象，持续填写 2-3 周后会有完整分析
- 当前显示的是框架，数据会逐渐填充

### Q3: NLP 模型安装失败？

**解决：**
1. 检查网络连接
2. 使用国内镜像：
   ```bash
   npm config set registry https://registry.npmmirror.com
   npm install @xenova/transformers
   ```
3. 如仍失败，可跳过 NLP 功能，不影响其他功能

### Q4: 如何查看历史数据？

**查看累计数据：**
```bash
cat /Users/liwang/.openclaw/workspace/daily-output/relationship/weekly-stats/cumulative-summary.md
```

**查看总复盘报告：**
```bash
cat /Users/liwang/.openclaw/workspace/agents/review-system/total-review/YYYY-MM-DD-review.md
```

### Q5: 如何修改发送时间？

**修改 Cron 配置：**
```bash
openclaw cron list  # 查看当前配置
openclaw cron update --jobId <任务 ID> --patch '{"schedule":{"expr":"0 19 * * 0"}}'
```

---

## 📞 技术支持

**文档：** `/workspace/agents/review-system/castle-six-analysis-framework.md`  
**日志：** `/workspace/logs/`  
**配置：** `/workspace/agents/review-system/castle-six-deep-complete.md`

---

**💕 城堡关系堡 | 数据驱动关系改善！**  
**🏰 Castle Six | 科学复盘，持续进步！**
