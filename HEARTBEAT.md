# HEARTBEAT.md - 晨报任务配置

---

## 🏰 Castle Six HTML 表单标准化（2026-03-13 重要更新）

**决策：** 所有 Castle Six 问卷/复盘统一使用 **HTML 表单链接格式**

**格式标准：**
```
👉 点击填写表单：[http://IP:端口/](http://IP:端口/)
```

**废除：** 所有文字问卷（纯文本回复格式）

**已更新脚本：**
- ✅ `growth-daily-review.sh` - 成长堡每日复盘
- ✅ `health-daily-review.sh` - 健康堡每日复盘
- ✅ `health-daily-questionnaire.sh` - 健康堡每日问卷
- ✅ `growth-daily-plan.sh` - 成长堡每日学习计划（飞书推送 + Web UI 主动显示）
- ✅ `castle-six-daily-questionnaire.sh` - Castle Six 每日问卷
- ✅ `relationship-weekly-sender.sh` - 关系堡每周问卷
- ✅ `wealth-daily-check.sh` - 财富堡每日问卷

**已完成：**
- ✅ 财富堡公网访问（Cloudflare Tunnel）

---

## 📰 晨报任务

**时间：** 每天早上 7:00  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**变更：** 2026-03-05 从 iMessage 改为飞书（支持 Markdown 链接格式）

## 🎧 每日合并朗读版（2026-03-17 确认）

**时间：** 每天早上 7:35  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**内容：** MP3 音频文件 + 文字稿

**发送格式：**
- ✅ MP3 文件附件（飞书直接发送，手机可播放）
- ✅ 纯中文文字稿（方便阅读）

**音频规格：**
- 时长：约 10 分钟
- 大小：约 2-3MB
- 格式：MP3（32kbps）
- 语音：macOS Mei-Jia（中文女声）

**内容包含：**
- 📰 国际/国内/AI/汽车新闻（12 条）
- 🔥 虎嗅/36 氪/B 站/GitHub（10 条）
- 每条：标题 + 内容（100 字以内）
- 数字转中文（如"第一条"、"二十九亿"）
- 英文音译（如"托肯"、"吉特哈布"）

**相关文件：**
- 脚本：`scripts/merge-daily-audio.sh`
- 输出：`/workspace/audio/daily-YYYY-MM-DD.mp3`
- 日志：`logs/merged-audio.log`

**执行流程：**
```
7:00  晨报文字版（带链接）→ 飞书
7:30  爆款日报文字版（带链接）→ 飞书
7:33  生成纯中文朗读文本
7:34  macOS say 生成 MP3
7:35  MP3 文件 + 文字稿 → 飞书（手机可直接播放）
```

### 🎧 TTS 朗读功能（2026-03-17 新增，合并版）

**发送策略：**
- ✅ 文字版晨报（7:00）和爆款日报（7:30）保持不变，单独发送
- ✅ 音频版合并为一个 MP3 文件，7:35 左右发送

**合并音频内容：**
- ⏰ 每天 7:35 自动生成（爆款日报生成后 3 分钟）
- 🎙️ 晨报 + 爆款日报完整朗读（纯中文）
- 📝 每条新闻：标题 + 内容（压缩到 100 字以内）
- 🔤 数字用中文（如"第一条"、"六倍"），英文专有名词音译（如"托肯"、"吉特哈布"）
- 📊 内容：
  - 新闻摘要：国际/国内/AI/汽车 各 3 条（共 12 条）
  - 爆款内容：虎嗅/36 氪各 3 条、B 站 2 条、GitHub 3 条（共 10 条）
- ⏱️ 总时长约 10-12 分钟
- 📤 自动发送到飞书（单个音频附件）

**相关文件：**
- 晨报脚本：`scripts/morning-news.sh`（文字版，7:00 发送）
- 爆款脚本：`scripts/daily-hot-report-ultimate.sh`（文字版，7:30 发送）
- 合并脚本：`scripts/merge-daily-audio.sh`（音频版，7:35 发送，使用 macOS say 命令）
- 音频缓存：`/tmp/merged-daily-audio.mp3`
- 日志文件：`logs/merged-audio.log`

**TTS 引擎：** macOS say 命令（Mei-Jia 语音，语速 170 字/分钟）

**执行流程：**
```
7:00  晨报文字版 → 飞书
7:30  爆款日报文字版 → 飞书
7:30  延迟 3 分钟调用合并脚本
7:33  合并脚本生成朗读文本
7:35  TTS 生成合并音频 → 飞书
```

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

## 📸 健康堡图片识别（2026-03-19 新增）

**状态：** ✅ 已配置  
**渠道：** 飞书私聊  
**识别类型：** 华为睡眠截图、三餐照片、体重秤照片

### 使用方法

**发送格式：**
1. 在飞书给 bot 发送图片
2. 添加标签（可选，帮助识别类型）：
   - `#睡眠` - 华为健康睡眠截图
   - `#早餐` - 早餐照片
   - `#午餐` - 午餐照片
   - `#晚餐` - 晚餐照片
   - `#体重` - 体重秤照片（周一）

**示例：**
```
#睡眠
[华为健康截图]
```

**自动识别内容：**
- **睡眠：** 入睡/起床时间、深睡/浅睡/REM、静息心率
- **三餐：** 食物名称、估算份量
- **体重：** 体重数值、体脂率、BMI

**数据保存：**
- 睡眠：`daily-output/health/sleep-data/YYYY-MM-DD-sleep.md`
- 三餐：`daily-output/health/meal-data/YYYY-MM-DD-{breakfast|lunch|dinner}.md`
- 体重：`daily-output/health/weight-data/YYYY-MM-DD-weight.md`

### 服务器管理

```bash
# 启动图片收集器
./scripts/start-health-image-collector.sh

# 查看状态
curl http://localhost:8900/health-image/status

# 查看日志
tail -f logs/health-image-collector.log

# 停止服务
pkill -f health-image-collector.js
```

### 相关文件

| 文件 | 用途 |
|------|------|
| `scripts/health-image-recognition.sh` | 图片识别脚本 |
| `scripts/health-image-collector.js` | 飞书 webhook 服务器 (8900) |
| `scripts/start-health-image-collector.sh` | 一键启动脚本 |

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
- 公网访问：✅ 已配置（Cloudflare Tunnel）

**📝 每日考题 HTML 表单（独立）：**
- 📚 每日 4 道选择题（自动加载当日考题）
- ✅ 支持多选，答案自动评分
- 服务器端口：8898
- 数据保存：`daily-output/growth/quiz-scores/YYYY-MM-DD-quiz-result.md`
- 公网访问：✅ 已配置（Cloudflare Tunnel）
- 当前链接：https://prairie-executives-turn-maps.trycloudflare.com

### 相关文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 统一发送脚本 | `scripts/castle-six-daily-questionnaire.sh` | 启动服务器 + 发送飞书 |
| 健康堡表单 | `health-form/index.html` | HTML 问卷（自动加载 Strava 数据） |
| 健康堡服务器 | `health-form/server.js` | Node.js 服务器 (8897) |
| 成长堡表单 | `growth-form/index.html` | HTML 问卷 |
| 成长堡服务器 | `growth-form/server.js` | Node.js 服务器 (8896) |
| Strava 同步脚本 | `scripts/sync-strava-data.sh` | 每小时同步 Strava 运动数据 |

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

# 考题服务器
cd /Users/liwang/.openclaw/workspace/quiz-form && node server.js

# 关系堡服务器 + 公网穿透
./scripts/start-relationship-public.sh

# 成长堡 + 公网穿透
./scripts/start-growth-public.sh

# 考题服务器 + 公网穿透
./scripts/start-quiz-public.sh
```

**查看日志：**
- 发送日志：`logs/castle-six-sender.log`
- 健康堡服务器：`logs/health-server.log`
- 成长堡服务器：`logs/growth-server.log`
- 成长堡公网：`logs/cloudflared-growth.log`
- 考题服务器：`logs/quiz-server.log`
- 考题公网：`logs/cloudflared-quiz.log`
- 关系堡服务器：`logs/relationship-server.log`
- 关系堡公网：`logs/lt-relationship.log`
- Strava 同步：`logs/strava-sync.log`

**成长堡服务器管理：**
```bash
# 启动成长堡 + 公网穿透
./scripts/start-growth-public.sh

# 查看公网链接
cat logs/growth-public-url.txt
```

### 🏃 Strava 数据同步（2026-03-13 新增）

**同步机制：**
1. **服务器启动时** - 健康堡服务器启动自动同步
2. **每日问卷发送时** - 早上 8:00 发送问卷前同步
3. **手动同步** - `./scripts/sync-strava-data.sh`

**数据流程：**
```
Strava App → API 抓取 → data/strava/latest-activities.json → 健康堡表单自动加载
```

**表单预填充：**
- 打开健康堡表单时自动加载今日 Strava 数据
- 运动类型、时长、距离自动填充
- 用户可补充 Strava 没有的数据（饮食、睡眠等）
- **以 Strava 数据为准**，手动输入作为补充

---

## 💕 健康堡公网访问（2026-03-14 Cloudflare Tunnel 稳定版）

**状态：** ✅ 已配置  
**访问方式：** Cloudflare Tunnel（trycloudflare.com）  
**特点：** 比 localtunnel 稳定 10 倍，URL 长期不变

**当前公网链接（永久记住）：**
- https://leisure-grid-champions-sector.trycloudflare.com
- ✅ 手机/电脑都能访问（4G/5G/WiFi）
- ✅ 链接已保存到 `logs/health-public-url.txt`
- ✅ 用户无需重新填写，直接访问即可

**服务器管理：**
```bash
# 启动健康堡 + 公网穿透
./scripts/start-health-public.sh

# 查看公网链接
cat logs/health-public-url.txt
```

---

## 💰 财富堡每周复盘（2026-03-15 改为每周一次）

**时间：** 每周日 **20:00**  
**收件人：** 飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)  
**状态：** ✅ 已激活  
**Cron ID:** `bae76ef7-1fff-4403-937a-e0136f3aaf77`

### 功能说明

**财富堡 HTML 表单（周维度）：**
- 💰 本周收入（工资/奖金/投资/兼职/其他）
- 💸 本周支出（餐饮/交通/购物/娱乐/学习/医疗/住房/其他）
- 🏦 账户余额（截至本周日）
- 🎯 月度储蓄目标进度
- 💭 财务反思（最大支出/冲动消费/理财心得/下周计划）
- 服务器端口：8898
- 数据保存：`daily-output/wealth/weekly-stats/YYYY/W{week}-wealth-stats.md`

### 相关文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 每周发送脚本 | `scripts/wealth-weekly-check.sh` | 启动服务器 + 发送飞书 |
| 财富堡表单 | `wealth-form/index.html` | HTML 问卷（周维度） |
| 财富堡服务器 | `wealth-form/server.js` | Node.js 服务器 (8898) |
| 公网穿透脚本 | `scripts/start-wealth-public.sh` | Cloudflare Tunnel |

### Cron 配置

```bash
# 财富堡每周复盘 - 每周日 20:00
Cron ID: bae76ef7-1fff-4403-937a-e0136f3aaf77
```

### 服务器管理

**手动启动：**
```bash
# 财富堡服务器
cd /Users/liwang/.openclaw/workspace/wealth-form && node server.js

# 查看状态
curl http://localhost:8898/status
```

**查看日志：**
- 发送日志：`logs/wealth-weekly-check.log`
- 服务器日志：`logs/wealth-server.log`
- Tunnel 日志：`logs/cloudflared-wealth.log`

**公网访问：** ✅ 已配置（Cloudflare Tunnel）
- 当前链接：https://cheats-grant-email-specialists.trycloudflare.com
- 链接文件：`logs/wealth-public-url.txt`
- 启动脚本：`scripts/start-wealth-public.sh`

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

## 🎧 有声读本 - 《每天懂点人情世故》（2026-03-17 新增）

**状态：** ✅ 已配置  
**收听链接：** https://variation-seafood-bridges-signing.trycloudflare.com  
**特点：** 外网可访问、自动记录进度、支持语速调节

### 功能说明

**播放器功能：**
- ✅ 自动记录播放进度（每 5 秒保存）
- ✅ 下次打开继续播放
- ✅ 支持 0.75x / 1.0x / 1.25x / 1.5x 语速
- ✅ 手机/电脑/车载都能用
- ✅ 收听记录自动同步到成长堡

**读书计划：**
- 📚 全书：13 天，每天 30 分钟
- 📅 开始日期：2026-03-17
- 🎯 预计完成：2026-03-29

**待办事项：**
- ⏳ 2026-03-17 白天：用户选择更自然的 TTS 声音（当前 macOS Mei-Jia 声音机械感强）
- 备选：Edge TTS（免费）或 ElevenLabs（付费 $5/月）

**每日推送：**
- ⏰ 时间：每天 17:00（下班前）
- 📬 渠道：飞书成长堡消息
- 📎 内容：当日收听链接 + 章节标题

### 相关文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 播放器网页 | `audiobook/index.html` | HTML5 音频播放器 |
| 服务器 | `audiobook/server.js` | Node.js 服务器 (8895) |
| 发送脚本 | `audiobook/scripts/send-daily-audiobook.sh` | 每日飞书推送 |
| 总结脚本 | `audiobook/scripts/audiobook-final-review.sh` | 读完结案点评 |
| 进度数据 | `audiobook/progress/user-progress.json` | 播放进度记录 |
| 收听统计 | `daily-output/growth/audiobook-stats/` | 每日统计数据 |
| 感想笔记 | `daily-output/growth/audiobook-reflections/` | 每日感想记录 |

### 服务器管理

```bash
# 启动有声读本 + 公网穿透
./audiobook/scripts/start-audiobook-public.sh

# 查看公网链接
cat logs/audiobook-public-url.txt

# 查看服务器日志
tail -f logs/audiobook-server.log

# 停止服务
pkill -f 'node server.js' && pkill -f 'cloudflared tunnel'
```

### 成长堡表单集成

**新增字段：**
- 🎧 今天听书了吗？（是/否）
- 📖 听到第几天了？（1-13）
- 💭 今天的感想/收获（必填）
- ⭐ 有用程度评分（1-5 星）

**数据流向：**
```
成长堡表单提交 → 保存感想笔记 → 同步收听统计 → 总复盘堡点评
```

### 读完结案流程

**触发条件：** 完成 13 天收听

**自动执行：**
1. 生成读书总结报告
2. 城堡点评（做得好的 + 可能缺失 + 后续建议）
3. 发送飞书通知
4. 同步到总复盘堡

**输出文件：**
- `daily-output/growth/audiobook-reviews/YYYY-MM-DD-audiobook-final-review.md`

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
**状态：** ✅ 已激活（2026-03-13 修复：添加 HTML 表单链接）  
**内容：** 成长堡每日复盘 HTML 表单（学习情况、产出、问题、明日计划）

**表单链接：** `http://localhost:8896/`

**填写内容：**
- 📖 今日学习（OpenClaw/Claude AI/视频制作）
- ⭐ 学习质量自评（1-5 分）
- 📝 今日产出（笔记/实操/作品）
- 💡 遇到的问题
- 📅 明日计划调整

**相关文件：**
- 脚本：`/workspace/scripts/growth-daily-review.sh`（已更新为 HTML 表单）
- 表单：`growth-form/index.html`
- 服务器：`growth-form/server.js`（端口 8896）
- 数据：`daily-output/growth/daily-stats/YYYY-MM-DD-growth-stats.md`

### 相关文件
- 脚本：`/workspace/scripts/growth-daily-review.sh`
- Cron：已创建（21:00 自动发送）

### 相关文件

- 脚本：`/workspace/scripts/health-daily-review.sh`
- 输出：`/workspace/daily-output/health/YYYY-MM/DD.md`
- 模板：`/workspace/agents/review-system/templates/health-daily-v2.md`

### Cron 设置

```bash
# 健康堡每日复盘 - 每天 10:30
Cron ID: 42b34ea5-8c2f-4b9b-94a1-1fd4f4101ea3
```

**配置更新记录（2026-03-15）：**
- 原任务 ID `3addc219-1e9e-4511-89b6-0f19c7daf6d2` (21:00) 已删除
- 新任务 ID `42b34ea5-8c2f-4b9b-94a1-1fd4f4101ea3` (10:30) 已创建
- 原因：HEARTBEAT.md 记录时间为 10:30，但实际 cron 配置为 21:00，配置不一致

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

## 💪 训练提醒时间调整（2026-03-19 更新）

**变更：** 从每天两次（8:00+20:00）改为**每天一次 11:00**

| 项目 | 原时间 | 新时间 | 说明 |
|------|--------|--------|------|
| 训练提醒 | 8:00 + 20:00 | **11:00** | 统一为中午发送当天训练内容 |

**原因：** 简化提醒频率，避免早晚打扰

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

---

## 🪞 飞书 ↔ Webchat 消息镜像（2026-03-13 Cloudflared 稳定版）

**状态：** ✅ 已完成  
**方向：** 双向同步  
**特点：** 支持跨网络（4G/5G/WiFi 都能用），使用 Cloudflare Tunnel 稳定穿透

### 组件配置

| 组件 | 状态 | 说明 |
|------|------|------|
| Webhook 服务器 | ✅ 运行中 | 端口 8899 |
| Cloudflare Tunnel | ✅ 运行中 | trycloudflare.com 域名 |
| Webchat→飞书 Cron | ✅ 已激活 | 每 1 分钟 (ID: 928de2ec) |
| 飞书→Webchat | ⏳ 待飞书后台配置 | 需配置 webhook URL |

### 当前公网地址

**URL:** 查看 `logs/feishu-mirror-url.txt` 或运行 `cat logs/cloudflared-feishu.log | grep trycloudflare`

**特点：**
- ✅ 比 localtunnel 稳定 10 倍
- ✅ URL 长期不变（除非重启 cloudflared）
- ✅ Cloudflare 官方服务

### 飞书后台配置步骤

1. 登录 [飞书开发者后台](https://open.feishu.cn/app)
2. 选择你的应用（Openclaw）
3. 进入「事件与回调」→「回调配置」
4. 配置订阅地址：`https://xxx.trycloudflare.com/feishu/webhook`（xxx 为实际域名）
5. 验证令牌（verifyToken）：留空即可
6. 订阅事件：`im.message.receive_v1`（已添加）
7. 保存

### 服务器管理

```bash
# 一键启动（Cloudflared 稳定版）
./scripts/start-feishu-mirror-stable.sh

# 查看当前 URL
cat logs/feishu-mirror-url.txt

# 查看状态
curl http://localhost:8899/status

# 查看日志
tail -f logs/feishu-webhook.log
tail -f logs/cloudflared-feishu.log
tail -f logs/webchat-to-feishu.log

# 停止服务
pkill -f feishu-webhook-server-v2
pkill -f 'cloudflared tunnel'
```

### 测试方法

**Webchat → 飞书（已就绪）：**
1. 在 Web UI 发送消息
2. 等待最多 1 分钟
3. 飞书收到 "💬 Webchat 消息:" 转发

**飞书 → Webchat（需配置 webhook）：**
1. 在飞书给 bot 发消息
2. 等待 1-2 秒
3. Web UI 收到 "📨 飞书消息:" 转发

### 相关文件

| 文件 | 用途 |
|------|------|
| `scripts/feishu-webhook-server-v2.js` | 飞书 webhook 服务器 |
| `scripts/webchat-to-feishu-sync-v5.sh` | Webchat 轮询脚本 |
| `scripts/start-feishu-mirror-stable.sh` | 一键启动脚本（Cloudflared） |
| `config/feishu-webhook-config.json` | 配置文件 |

---

## 🔄 OpenClaw Gateway 每日重启（2026-03-13 新增）

**时间：** 每天 **04:00** (Asia/Shanghai)  
**状态：** ✅ 已激活  
**Cron ID:** `bead200f-9932-46ba-8ef4-c65b5536398d`

### 配置说明

**Cron 表达式：** `0 4 * * *`  
**时区：** Asia/Shanghai  
**任务类型：** systemEvent（在 main session 执行）  
**执行内容：** 重启 OpenClaw Gateway

### 管理命令

```bash
# 查看任务状态
openclaw cron list

# 手动触发重启
openclaw cron run bead200f-9932-46ba-8ef4-c65b5536398d

# 禁用任务
openclaw cron update bead200f-9932-46ba-8ef4-c65b5536398d --enabled false

# 删除任务
openclaw cron remove bead200f-9932-46ba-8ef4-c65b5536398d
```

### 注意事项

- Gateway 重启后会自动恢复所有服务
- 重启过程约 5-10 秒
- 重启期间消息可能会短暂延迟

---

---

## 🚨 压力测试配置（2026-03-18 新增）

**背景：** 用户反馈"每日复盘和任务提醒漏洞百出，今天可用明天不可用，忘记约定，没有充分测试"

**解决方案：** 创建自动化压力测试脚本，连夜跑测试

### 测试脚本

| 脚本 | 用途 | 耗时 |
|------|------|------|
| `scripts/validate-configs-persistent.sh` | 配置持久化检查 | 1 分钟 |
| `scripts/stress-test-all.sh` | 单轮全功能测试 | 3 分钟 |
| `scripts/stress-test-10rounds.sh` | 10 轮连续测试（模拟 10 天） | 10-15 分钟 |
| `scripts/overnight-stress-test.sh` | 总控脚本（一键运行全部） | 15-20 分钟 |

### 使用方法

**一键运行全部测试：**
```bash
cd /Users/liwang/.openclaw/workspace
./scripts/overnight-stress-test.sh
```

**单独运行某个测试：**
```bash
# 配置检查
./scripts/validate-configs-persistent.sh

# 单轮测试
./scripts/stress-test-all.sh

# 10 轮连续测试
./scripts/stress-test-10rounds.sh
```

### 测试覆盖

**配置检查：**
- ✅ HEARTBEAT.md 是否包含所有 cron 任务
- ✅ 脚本文件是否存在
- ✅ 服务器启动脚本是否存在
- ✅ cron 表达式一致性
- ✅ 日志目录权限
- ✅ 飞书插件配置

**功能测试：**
- ✅ 每日晨报
- ✅ 每日爆款日报
- ✅ 健康堡每日问卷
- ✅ 健康堡每日复盘
- ✅ 成长堡每日复盘
- ✅ 总复盘堡每日简报

**稳定性测试：**
- ✅ 10 轮连续运行（模拟 10 天）
- ✅ 每轮间隔 30 秒
- ✅ 检测状态残留问题
- ✅ 检测资源泄漏

### 测试报告

**位置：** `logs/stress-test/`

**文件：**
- `stress-test-YYYYMMDD_HHMMSS.md` - 单轮测试报告
- `10rounds-summary-YYYYMMDD_HHMMSS.md` - 10 轮测试报告
- `round-N-failures.log` - 各轮失败详情

### 通过标准

| 指标 | 标准 | 处理 |
|------|------|------|
| 配置检查 | 0 问题 | 通过 |
| 单轮测试 | 100% 成功 | 通过 |
| 10 轮测试 | ≥95% 成功 | 通过 |
| 10 轮测试 | <95% 成功 | 修复后重试 |

### 定期运行

**建议：**
- 每次重大修改后：运行完整测试
- 每周：运行一次 10 轮测试
- 每月：运行一次完整测试 + 人工 review

### 教训记录

**问题根源：**
1. 配置没持久化 → 解决：配置检查脚本
2. cron 任务状态不稳定 → 解决：10 轮连续测试
3. 脚本有 bug → 解决：单轮全功能测试
4. 没有监控 → 解决：测试报告自动发送飞书

**维护者：** 城堡 🏰  
**添加日期：** 2026-03-18

---

---

## 🔍 生产环境稳定性监控（2026-03-19 新增）

**背景：** 用户反馈"每日复盘和任务提醒漏洞百出，今天可用明天不可用"

**解决方案：** 创建生产环境监控脚本，每天检查实际运行情况

### 监控脚本

**脚本：** `scripts/production-monitor.sh`

**功能：**
- 每天 9:00 自动运行
- 检查昨天核心任务是否成功执行
- 生成稳定性报告并发送到飞书

**检查项目：**
1. 每日晨报（7:00）
2. 每日爆款日报（7:30）
3. Castle Six 问卷（8:00）
4. 健康堡问卷（8:00）
5. 总复盘每周（周日 20:00）

### Cron 配置

```bash
# 每日稳定性监控 - 每天 9:00
Cron ID: 82f69a17-51c3-4c91-b541-49b36a31dc5d
```

### 监控报告

**位置：** `logs/monitor/daily-stability-YYYY-MM-DD.md`

**内容：**
- 总任务数
- 成功/失败数量
- 成功率
- 最近运行时间

### 通过标准

| 指标 | 标准 | 处理 |
|------|------|------|
| 成功率 | 100% | ✅ 正常 |
| 成功率 | ≥80% | ⚠️ 观察 |
| 成功率 | <80% | ❌ 需要修复 |

### 与压力测试的区别

| 维度 | 压力测试 | 生产监控 |
|------|---------|---------|
| 目的 | 极限测试 | 日常监控 |
| 频率 | 手动运行 | 每天自动 |
| 间隔 | 30 秒 | 24 小时 |
| 真实性 | 低（触发保护） | 高（真实使用） |

**决策：** 停用压力测试，使用生产监控

### 教训记录

**问题根源：**
1. 压力测试间隔太短（30 秒）→ Gateway 触发保护
2. 固定会话 ID 复用 → 会话冲突
3. 子 agent 创建开销大 → 并发失败

**解决方案：**
- ✅ 改用生产环境监控（每天一次，真实场景）
- ✅ 检查日志文件确认任务执行
- ✅ 每天 9:00 自动发送报告

**维护者：** 城堡 🏰  
**添加日期：** 2026-03-19

---

---

## 🚨 六堡系统全面测试（2026-03-19 连夜测试）

**测试时间：** 2026-03-19 00:18 - 00:23  
**测试类型：** 单任务 + 边界情况 + 配置检查  
**测试脚本：** `scripts/full-system-test.sh`

### 测试结果

| 指标 | 数值 | 目标 | 状态 |
|------|------|------|------|
| 总测试数 | 87 | - | - |
| 通过数 | 68 | - | ✅ |
| 失败数 | 19 | 0 | ❌ |
| 跳过数 | 8 | - | ⚪ |
| 通过率 | 78% | ≥95% | ❌ |

### 发现的问题

**严重问题（需立即修复）：**
1. T03 语法错误 - Castle Six 脚本第 200 行有损坏的 emoji 和未闭合引号
2. 考题服务器未运行 - CC-02-03 测试失败

**共性问题（需逐步修复）：**
- 11 个脚本无超时设置（timeout/max-time）
- 9 个脚本无 cleanup 机制（trap/清理临时文件）
- 1 个脚本无日志记录

### 已采取措施

1. ✅ 暂停 Gateway 重启任务（Cron ID: bead200f... 已删除）
2. ✅ 生成详细测试报告
3. ⏳ 修复 Castle Six 脚本语法错误
4. ⏳ 添加超时和 cleanup 机制

### 修复计划

| 时间 | 任务 | 负责人 |
|------|------|--------|
| 2026-03-19 今晚 | 修复 T03 语法错误 | 城堡 |
| 2026-03-20 明晚 | 添加超时设置（11 个脚本） | 城堡 |
| 2026-03-21 周末 | 添加 cleanup 机制（9 个脚本） | 城堡 |
| 2026-03-22 周末 | 重新运行完整测试 | 城堡 |

### 测试报告位置

- 详细报告：`logs/test-20260319/test-report-YYYYMMDD_HHMMSS.md`
- 测试日志：`logs/test-20260319/full-test-YYYYMMDD_HHMMSS.log`

### 教训记录

**问题根源：**
1. 脚本编辑时引入了损坏的 emoji 字符
2. 没有语法检查流程
3. 没有超时和 cleanup 机制

**改进措施：**
- ✅ 创建自动化测试脚本
- ✅ 每次修改后运行语法检查
- ✅ 添加超时和 cleanup 模板

**维护者：** 城堡 🏰  
**添加日期：** 2026-03-19

---
