# HEARTBEAT.md - 晨报任务配置

## 📰 晨报任务

**时间：** 每天早上 7:00  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**变更：** 2026-03-05 从 iMessage 改为飞书（支持 Markdown 链接格式）

## 🔥 每日爆款日报

**时间：** 每天早上 7:30  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**变更：** 2026-03-08 从 7:05 改为 7:30，修复 cron PATH 问题  
**内容：** 虎嗅、36 氪、B 站、GitHub 等热门内容（每渠道 10 条带链接）

### 相关文件

- 脚本：`/workspace/scripts/daily-hot-report-ultimate.sh`
- 日志：`/workspace/logs/daily-hot-report.log`
- 报告：`/workspace/reports/daily-hot/hot-report-ultimate-YYYY-MM-DD.md`

### Cron 设置

```bash
# 每日爆款日报 - 每天早上 7:30
30 7 * * * cd /Users/liwang/.openclaw/workspace && ./scripts/daily-hot-report-ultimate.sh >> logs/daily-hot-report.log 2>&1
```

**修复记录：**
- 2026-03-08: 添加 PATH 导出到脚本开头，解决 cron 环境变量问题
- 2026-03-08: 从 7:05 改为 7:30 发送（用户要求）

---

## 🌤️ 天气预报任务

**时间：** 每天早上 7:00  
**收件人：** **飞书** (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活（2026-03-05 新增）  
**变更：** 2026-03-09 从 iMessage 改为飞书（Castle Six 统一渠道）  
**内容：** 上海当前天气 + 未来 3 天预报

## 📊 每日信息小结

**时间：** 每天晚上 21:30  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**变更：** 2026-03-05 从 iMessage 改为飞书（与晨报保持一致）  
**内容：** 定时任务统计、软件安装、讨论话题、错误与整改、Token 消耗

### 新闻分类（每类 5 条）

| 分类 | 新闻源 |
|------|--------|
| 🌍 国际 | 澎湃新闻、联合早报、虎嗅、钛媒体 |
| 🇨🇳 国内 | 澎湃新闻、新华网、钛媒体、人民网 |
| 🤖 AI | 钛媒体、虎嗅、IT 之家 |
| 🚗 汽车 | 新华网汽车、汽车之家、钛媒体 |

---

## 💪📚 Castle Six HTML 表单问卷（2026-03-12 新增）

**时间：** 每日 **8:00 AM**  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**Cron ID:** `434aa838-72ec-46b9-aaed-1f2719e56fd4`

### 功能说明

**健康堡 HTML 表单：**
- 🏃 运动训练（Strava 自动同步）
- 🍽️ 饮食记录（早/午/晚餐 + 夜宵）
- 😴 睡眠质量（入睡/起床/深睡/浅睡/REM/心率）
- ⚖️ 体重记录（仅周一填写）
- 服务器端口：8897
- 数据保存：`daily-output/health/daily-stats/YYYY-MM-DD-health-stats.md`

**成长堡 HTML 表单：**
- 📖 今日学习（OpenClaw/Claude AI/视频制作）
- ⭐ 学习质量自评（1-5 分）
- 📝 今日产出（笔记/实操/作品）
- 💡 问题与明日计划
- 服务器端口：8896
- 数据保存：`daily-output/growth/daily-stats/YYYY-MM-DD-growth-stats.md`

### 相关文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 统一发送脚本 | `scripts/castle-six-daily-questionnaire.sh` | 启动服务器 + 发送飞书 |
| 健康堡表单 | `health-form/index.html` | HTML 问卷 |
| 健康堡服务器 | `health-form/server.js` | Node.js 服务器 (8897) |
| 成长堡表单 | `growth-form/index.html` | HTML 问卷 |
| 成长堡服务器 | `growth-form/server.js` | Node.js 服务器 (8896) |

### Cron 配置

```bash
# Castle Six 每日问卷发送 - 每天早上 8:00
0 8 * * * cd /Users/liwang/.openclaw/workspace && ./scripts/castle-six-daily-questionnaire.sh
```

### 服务器管理

**手动启动：**
```bash
# 健康堡服务器
cd /Users/liwang/.openclaw/workspace/health-form && node server.js

# 成长堡服务器
cd /Users/liwang/.openclaw/workspace/growth-form && node server.js

# 关系堡服务器 + 公网穿透
./scripts/start-relationship-public.sh
```

**查看日志：**
- 发送日志：`logs/castle-six-sender.log`
- 健康堡服务器：`logs/health-server.log`
- 成长堡服务器：`logs/growth-server.log`
- 关系堡服务器：`logs/relationship-server.log`
- 关系堡公网：`logs/lt-relationship.log`

---

## 💕 关系堡公网访问（2026-03-12 新增）

**状态：** ✅ 已配置  
**访问方式：** 内网穿透（localtunnel）  
**特点：** 任何网络环境都能访问（4G/5G/WiFi）

**当前公网链接：**
- https://rare-snakes-play.loca.lt
- （每次重启会变化，自动发送到飞书）

**服务器管理：**
```bash
# 启动关系堡 + 公网穿透
./scripts/start-relationship-public.sh

# 查看公网链接
cat logs/lt-relationship.log | grep "loca.lt"
```

**使用说明：**
- ✅ 无需同一 WiFi
- ✅ 手机/电脑都能用
- ⚠️ 首次访问提示"不安全"是正常的
- 🔄 每次重启链接会变，自动发送到飞书

---

## 💪 健康堡每日复盘（Castle Six）

**时间：** 每日 **10:30**  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**变更：** 2026-03-10 从 21:30 改为 10:30（确保包含完整睡眠数据）  
**内容：** 健康堡每日复盘报告（运动、睡眠、饮食）

---

## 📚 成长堡每日复盘（Castle Six）

**时间：** 每日 **21:00**  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**内容：** 成长堡每日复盘问卷（学习情况、产出、问题、明日计划）

### 相关文件
- 脚本：`/workspace/scripts/growth-daily-review.sh`
- Cron：已创建（21:00 自动发送）

### 相关文件

- 脚本：`/workspace/scripts/health-daily-review.sh`
- 输出：`/workspace/daily-output/health/YYYY-MM/DD.md`
- 模板：`/workspace/agents/review-system/templates/health-daily-v2.md`

### Cron 设置

```bash
# 健康堡每日复盘 - 每天 21:30
已通过 openclaw cron add 创建任务 ID: 0ae248f4-8618-4ef8-afef-5cfe35a31451
```

---

## 📬 Castle Six 渠道统一（2026-03-09）

**变更：** 所有城堡六堡相关输出统一改为飞书发送

| 任务 | 原渠道 | 新渠道 | 脚本 |
|------|--------|--------|------|
| 健康日报 | iMessage | 飞书 | `health-report.sh` |
| 训练提醒 | iMessage | 飞书 | `training-reminder.sh` |
| 运动分析 | iMessage | 飞书 | `analyze-workout.sh` |
| 训练计划 | iMessage | 飞书 | `update-training-plan.sh` |
| 天气预报 | iMessage | 飞书 | `weather-report.sh` |
| 健康堡日报 | - | 飞书 | `health-daily-review.sh` |

---

### 输出格式

```
📰 晨报 - YYYY 年 M 月 D 日

🌍 国际新闻
1. 新闻标题
https://完整链接

2. 新闻标题
https://完整链接

... (每类 5 条)

---
🏰 城堡晨报 | 自动发送
```

**注意：** 链接必须单独成行，前后各一个空行，确保 iMessage 识别为可点击超链接。

### 执行流程

1. **7:00 AM** - 定时任务触发
2. **抓取** - 从 14 个稳定新闻源抓取最新内容
3. **整理** - AI 智能提取每类 5 条新闻
4. **发送** - 通过 iMessage 发送晨报
5. **记录** - 写入 memory/YYYY-MM-DD.md

### 相关文件

- 脚本：`/workspace/scripts/morning-news.sh`
- AI 脚本：`/workspace/scripts/morning-news-ai.js`
- 配置：`/workspace/memory/2026-03-03.md`
- 日志：`/workspace/logs/morning-news.log`

### Cron 设置

```bash
# 晨报 - 每天早上 7:00
0 7 * * * cd /Users/liwang/.openclaw/workspace && ./scripts/morning-news.sh >> logs/morning-news.log 2>&1

# 配置验证 - 每天早上 6:55（晨报前 5 分钟）
55 6 * * * cd /Users/liwang/.openclaw/workspace && ./scripts/validate-configs.sh >> logs/config-validation.log 2>&1
```

**修复记录：**
- 2026-03-05: 修复 cron 环境中 `openclaw` 命令路径问题，改为 `/opt/homebrew/bin/openclaw`
- 2026-03-05: 添加配置验证脚本，每天自动检查配置状态

---

**首次测试：** 2026-03-03 已完成 ✅  
**正式运行：** 2026-03-04 07:00 开始

---

## 🏰 总复盘堡（Castle Six）- v2.0 改进版

**时间：** 
- 每日简报：21:45
- 每周复盘：周日 20:00
- 每月总结：月末 20:00

**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活（2026-03-10 新增）  
**版本：** v2.0（2026-03-10 改进）

### 改进内容（v2.0）

**✅ 已完成：**
1. 数据真实化 - 从健康堡/成长堡真实读取数据
2. 目标对比 - 增加目标 vs 实际对比表
3. 智能评分 - 根据实际数据动态计算评分
4. 行动跟踪 - 创建行动跟踪文件

**⏳ 进行中：**
5. 深度分析 - 关联分析 + 根因分析（5 Why 法）
6. 行动闭环 - 跟踪行动执行情况

### 相关文件
- 每日简报：`scripts/total-daily-brief.sh`（v2.0）
- 每周复盘：`scripts/total-weekly-review.sh`（v2.0）
- 每月总结：`scripts/total-monthly-summary.sh`
- 目标配置：`goals/targets.md`
- 行动跟踪：`data/total-review/action-tracker.md`
- 数据存储：`data/total-review/`
- PDF 报告：`reports/total-review/`
- 复盘方法论：`docs/fu-pan-method-guide.md`

### Cron 配置
- 每日简报：`45 21 * * *` (任务 ID: 5f2ec99b-dabb-4f6a-93fd-624befb636b3)
- 每周复盘：`0 20 * * 0` (任务 ID: d4bf3a50-7c4e-4a0d-a214-4d1497e7b0ee)
- 每月总结：`0 20 28-31 * *` (任务 ID: 2990a6f4-882f-4b6f-a662-5d91908e04a7)

### PDF 存档
- 每周复盘 PDF：`reports/total-review/weekly/YYYY/W{week}-total-review.pdf`
- 每月总结 PDF：`reports/total-review/monthly/YYYY/YYYY-MM-total-review.pdf`

**用途：** 月度/季度/年度复盘时调用历史数据

### 复盘方法论

基于《复盘》（虚舟 著）核心理念：
- **复盘三角：** 目标 + 结果 + 过程
- **七步法：** 回顾目标 → 评估结果 → 分析原因 → 总结规律 → 制定计划 → 执行跟踪 → 再次复盘
- **核心价值：** 避免重复犯错、提炼成功经验、提升认知水平
