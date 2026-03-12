# MEMORY.md - 长期记忆

**最后更新：** 2026-03-05  
**维护者：** 城堡 🏰

---

## 📌 重要配置决策

### 晨报发送渠道（2026-03-05 确认）

- **渠道：** 飞书
- **目标：** ou_7781abd1e83eae23ccf01fe627f0747f
- **格式：** `[标题](链接)`，澎湃新闻下划线需编码 `_` → `%5F`
- **原因：** 飞书支持 Markdown 链接格式，显示效果更好

### 配置中心建立（2026-03-05）

**背景：** 晨报配置变更时出现遗漏，旧脚本未删除导致重复发送

**改进措施：**
1. 创建 `/workspace/config/active-configs.json` - 配置中心
2. 创建 `/workspace/scripts/validate-configs.sh` - 自动验证脚本
3. 创建 `/workspace/scripts/config-manager.sh` - 配置管理工具
4. 创建 `/workspace/CHECKLIST.md` - 配置变更检查清单
5. 每天 6:55 自动运行配置验证（晨报前 5 分钟）

**教训：**
- 配置变更时必须清理旧配置
- cron 环境需要使用完整命令路径
- 建立系统性管理避免依赖零散记忆

---

## 👤 用户信息

- **姓名：** 海皇堡
- **时区：** Asia/Shanghai
- **称呼：** 海皇堡

---

## 🤖 我的身份

- **名称：** 城堡
- **Emoji：** 🏰
- **定位：** AI 助手 / 数字管家
- **风格：** 可靠、直接、有点幽默

---

## 📅 日常任务

| 时间 | 任务 | 渠道 |
|------|------|------|
| 6:55 | 配置验证（自动） | 日志 |
| 7:00 | 晨报 | **飞书** |
| 7:00 | 上海天气预报 | iMessage |
| 7:30 | 健康日报 | iMessage |
| 8:00 | 训练提醒（当天） | iMessage |
| 9:00 | 运动数据分析 | iMessage |
| 9:30 | 训练计划检查 | iMessage |
| 20:00 | 训练提醒（预告） | iMessage |
| 21:30 | 每日信息小结 | iMessage |

---

## 🔧 技术环境

- **OpenClaw 路径：** `/opt/homebrew/bin/openclaw`
- **Node 路径：** `/opt/homebrew/bin/node`
- **工作区：** `/Users/liwang/.openclaw/workspace`
- **系统：** macOS (Darwin 25.2.0, arm64)

---

## 📚 重要文档

- **配置中心：** `/workspace/config/active-configs.json`
- **配置变更清单：** `/workspace/CHECKLIST.md`
- **晨报配置：** `/workspace/HEARTBEAT.md`
- **每日记录：** `/workspace/memory/YYYY-MM-DD.md`

---

## ⚠️ 注意事项

1. **配置变更流程：** 修改前搜索相关文件 → 修改后验证 → 清理旧配置
2. **cron 环境：** 命令必须使用完整路径（如 `/opt/homebrew/bin/openclaw`）
3. **飞书格式：** Markdown 链接，下划线需 URL 编码
4. **验证机制：** 每天 6:55 自动验证，日志在 `logs/config-validation.log`

---

## 📬 发送渠道配置（2026-03-09 最终版）

**重要变更：** 2026-03-09 起，所有 Castle Six（城堡六堡）相关输出统一改为飞书发送

| 任务 | 渠道 | 目标 |
|------|------|------|
| 晨报 (7:00) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 天气预报 (7:00) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 健康日报 (7:35) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 训练提醒 (8:00) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 运动分析 (9:00) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 训练计划检查 (9:30) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 训练预告 (20:00) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 健康堡日报 (21:30) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |
| 每日小结 (21:30) | **飞书** | ou_7781abd1e83eae23ccf01fe627f0747f |

**脚本渠道：**
- 晨报：`morning-news.sh` → 飞书
- 健康/训练：`health-report.sh`, `training-reminder.sh`, `analyze-workout.sh`, `update-training-plan.sh`, `health-daily-review.sh` → **飞书** (`openclaw message send`)
- 天气：`weather-report.sh` → **飞书**

---

**这是 curated memory（精选记忆），日常详细记录在 `memory/YYYY-MM-DD.md`**
