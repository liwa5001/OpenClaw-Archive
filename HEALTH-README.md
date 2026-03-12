# 🚴 城堡健康追踪系统

## 📋 系统概览

基于 Strava 数据的完整健康追踪系统，包括日报、周报、年报、个性化训练计划和智能调整。

**状态：** ✅ 已激活  
**开始日期：** 2026-03-03  
**用户：** Li Wang (Strava ID: 77463804)

**最新升级：**
- ✅ 每天两次训练提醒（提前 1 天 + 提前 1 小时）
- ✅ 详细准备清单和注意事项
- ✅ 运动后数据分析（次日 9:00）
- ✅ 智能训练计划调整（需用户同意）

---

## 🎯 训练目标

**12 周长距离有氧训练计划**
- **当前：** 单次骑行 25-36 km
- **目标：** 单次骑行 100 km+
- **结束日期：** 2026-05-26

---

## 📊 报告系统

| 报告类型 | 发送时间 | 内容 | 状态 |
|---------|---------|------|------|
| 📰 晨报 | 每天 7:00 AM | 新闻 20 条 | ✅ 已配置 |
| 📊 健康日报 | 每天 7:30 AM | 昨日运动 + 今日计划 | ✅ 已配置 |
| 🔔 训练提醒 | 每天 8:00 AM | 当天训练详情（含热身/冷身） | ✅ 已配置 |
| 🌙 训练预告 | 每天 8:00 PM | 明天训练 + 准备清单 | ✅ 已配置 |
| 📊 运动分析 | 每天 9:00 AM | 昨日数据 + 调整建议 | ✅ 已配置 |
| 🔧 计划调整 | 每天 9:30 AM | 检查同意并执行 | ✅ 已配置 |
| 📈 健康周报 | 周一 8:30 AM | 本周统计 + 趋势 | ✅ 已配置 |
| 📉 健康年报 | 1/1 9:00 AM | 年度总结 + 目标 | ✅ 已配置 |

---

## 📁 文件结构

```
/Users/liwang/.openclaw/workspace/
├── docs/
│   ├── training-plan.md (12 周训练计划)
│   └── strava-health-config.md (系统配置)
├── scripts/
│   ├── morning-news.sh (晨报脚本)
│   ├── training-reminder.sh (训练提醒)
│   └── health-report.sh (健康报告)
├── data/
│   └── strava/ (运动数据)
├── reports/
│   ├── weekly/ (周报)
│   └── yearly/ (年报)
├── logs/
│   ├── morning-news.log
│   └── health-tracker.log
└── HEALTH-README.md (本文档)
```

---

## 🔧 脚本说明

### 1. training-reminder.sh

**功能：** 根据星期几发送当天训练提醒

**使用：**
```bash
./training-reminder.sh
```

**输出示例：**
```
🚴 训练提醒 - 2026 年 03 月 03 日

📋 今日训练：基础耐力骑行
📏 距离：30 km
💪 强度：Z2
💓 心率：120-140 bpm

💡 提示：保持有氧区间，不要过快！热身 10 分钟，冷身 5 分钟。🚴

---
🏰 城堡健康追踪 | 加油！
```

### 2. health-report.sh

**功能：** 生成日报/周报/年报

**使用：**
```bash
./health-report.sh daily    # 日报
./health-report.sh weekly   # 周报
./health-report.sh yearly   # 年报
```

### 3. morning-news.sh

**功能：** 晨报 + 健康摘要

**使用：**
```bash
./morning-news.sh
```

---

## ⏰ 定时任务 (Crontab)

```bash
# 查看当前配置
crontab -l

# 编辑配置
crontab -e
```

**当前配置：**
```bash
# 晨报 - 每天早上 7:00
0 7 * * * ./scripts/morning-news.sh

# 健康日报 - 每天早上 7:30
30 7 * * * ./scripts/health-report.sh daily

# 训练提醒（当天）- 每天早上 8:00
0 8 * * * ./scripts/training-reminder.sh

# 训练提醒（预告）- 每天晚上 8:00
0 20 * * * ./scripts/training-reminder.sh

# 运动数据分析 - 每天早上 9:00
0 9 * * * ./scripts/analyze-workout.sh

# 检查训练计划调整 - 每天早上 9:30
30 9 * * * ./scripts/update-training-plan.sh check

# 健康周报 - 每周一 8:30
30 8 * * 1 ./scripts/health-report.sh weekly

# 健康年报 - 每年 1 月 1 日 9:00
0 9 1 1 * ./scripts/health-report.sh yearly
```

---

## 🚴 12 周训练计划

### 阶段 1：基础建设期（第 1-4 周）

| 周 | 重点 | 长距离目标 |
|----|------|-----------|
| 1 | 建立习惯 | 30 km |
| 2 | 增加距离 | 35 km |
| 3 | 持续进步 | 40 km |
| 4 | 恢复调整 | 20 km |

### 阶段 2：耐力提升期（第 5-8 周）

| 周 | 重点 | 长距离目标 |
|----|------|-----------|
| 5 | 提升耐力 | 50 km |
| 6 | 挑战自我 | 60 km |
| 7 | 突破极限 | 70 km |
| 8 | 恢复调整 | 30 km |

### 阶段 3：强化期（第 9-12 周）

| 周 | 重点 | 长距离目标 |
|----|------|-----------|
| 9 | 强化训练 | 80 km |
| 10 | 接近目标 | 90 km |
| 11 | 最后准备 | 100 km |
| 12 | 挑战 100 km | 100 km+ |

---

## 💓 心率区间

| 区间 | 名称 | 心率 | 用途 |
|------|------|------|------|
| Z1 | 恢复区 | 100-120 bpm | 恢复、热身 |
| Z2 | 有氧区 | 120-140 bpm | 长距离有氧 |
| Z3 | 节奏区 | 140-160 bpm | 乳酸阈值 |
| Z4 | 无氧区 | 160-180 bpm | 间歇训练 |
| Z5 | 极限区 | 180+ bpm | 最大摄氧 |

**长距离训练主要在 Z2 区间（120-140 bpm）**

---

## 📱 接收设置

**iMessage 接收人：** liwa5001@hotmail.com

**修改接收人：**
编辑脚本中的 `--to` 参数：
```bash
imsg send --to "YOUR_NUMBER" --text "..."
```

---

## 🔧 故障排查

### 查看日志

```bash
# 晨报日志
tail -f logs/morning-news.log

# 健康追踪日志
tail -f logs/health-tracker.log
```

### 测试脚本

```bash
# 测试训练提醒
./scripts/training-reminder.sh

# 测试健康日报
./scripts/health-report.sh daily
```

### 常见问题

**Q: 没收到提醒？**
- 检查 crontab 是否运行：`crontab -l`
- 查看日志：`logs/health-tracker.log`
- 确认 iMessage 正常：`imsg chats --limit 5`

**Q: Strava 数据不更新？**
- 检查 token 是否过期
- 重新获取 access token

**Q: 训练计划太累？**
- 降低强度到 Z1
- 增加休息日
- 延长恢复时间

---

## 📊 Strava API

**当前 Token：** `6aeed1494bb2dc71a383480adffd167d6e39fc09`

**Token 过期处理：**
1. 访问 Strava API 设置
2. 重新获取 access token
3. 更新脚本中的 `STRAVA_TOKEN` 变量

**API 限制：**
- 每 15 分钟 100 次请求
- 每日 1000 次请求
- 当前使用频率：安全 ✅

---

## 🎯 进度追踪

### 每周记录

- [ ] 总骑行距离
- [ ] 平均心率
- [ ] 平均功率
- [ ] 体重变化
- [ ] 静息心率
- [ ] 睡眠质量

### 里程碑

- [ ] 第 4 周：完成 40 km 骑行
- [ ] 第 8 周：完成 70 km 骑行
- [ ] 第 12 周：完成 100 km 骑行 🎉

---

## 🔧 训练计划调整流程

### 自动分析流程

```
每天 9:00 AM → 分析昨天运动数据
           ↓
    生成分析报告
           ↓
    评估是否需要调整
           ↓
    发送建议给你
           ↓
    等待你的回复
           ↓
每天 9:30 AM → 检查是否同意
           ↓
    如同意则更新计划
```

### 调整类型

| 情况 | 建议 | 调整内容 |
|------|------|---------|
| 心率过高 | 降低强度 | 心率区间 -10 bpm |
| 心率过低 | 保持或增加 | 维持当前或 +5 bpm |
| 距离未完成 | 保持当前 | 继续适应 1 周 |
| 体感疲劳 | 增加恢复 | 增加 1 个休息日 |

### 如何同意调整

收到调整建议后，回复以下任一：
- "同意调整"
- "yes"
- "1"
- "好的"

系统会在 9:30 AM 检查并执行调整。

### 调整日志

查看调整历史：
```bash
cat logs/training-adjustments.log
```

---

## 📞 支持

**文档位置：** `/Users/liwang/.openclaw/workspace/HEALTH-README.md`

**训练计划：** `/Users/liwang/.openclaw/workspace/docs/training-plan.md`

**系统配置：** `/Users/liwang/.openclaw/workspace/docs/strava-health-config.md`

**分析脚本：** `/Users/liwang/.openclaw/workspace/scripts/analyze-workout.sh`

**调整脚本：** `/Users/liwang/.openclaw/workspace/scripts/update-training-plan.sh`

---

**最后更新：** 2026-03-03 13:54  
**下次报告：** 2026-03-04 07:00 (晨报 + 健康日报)  
**下次训练：** 2026-03-04 08:00 (训练提醒)

---

🏰 城堡健康追踪 | 加油，海皇堡！💪
