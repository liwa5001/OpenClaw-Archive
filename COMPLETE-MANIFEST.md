# OpenClaw Archive 完整归档清单

**创建日期：** 2026-03-12  
**GitHub:** https://github.com/liwa5001/OpenClaw-Archive  
**维护者：** 城堡 (海皇堡)

---

## 📦 归档内容总览

### 📁 根目录文档 (13 个文件)
- AGENTS.md - Agent 工作指南
- SOUL.md - AI 助手身份定义
- USER.md - 用户信息
- MEMORY.md - 长期记忆
- HEARTBEAT.md - 定时任务配置
- IDENTITY.md - 身份标识
- TOOLS.md - 工具配置
- QUICK-REFERENCE.md - 快速参考
- CHECKLIST.md - 配置变更清单
- BOOTSTRAP.md - 初始化指南
- HEALTH-README.md - 健康堡说明

### 📁 scripts/ - 核心脚本 (约 30 个)
**Castle Six 相关：**
- castle-six-daily-questionnaire.sh - 每日问卷发送
- health-daily-review.sh - 健康堡每日复盘
- growth-daily-review.sh - 成长堡每日复盘
- total-review-scientific-full.js - 科学总复盘
- relationship-weekly-sender.sh - 关系堡每周问卷

**晨报相关：**
- morning-news.sh - 晨报发送
- morning-news-ai.js - AI 新闻整理
- daily-hot-report-ultimate.sh - 每日爆款日报

**健康堡相关：**
- health-report.sh - 健康日报
- training-reminder.sh - 训练提醒
- analyze-workout.sh - 运动分析
- update-training-plan.sh - 训练计划更新

**成长堡相关：**
- growth-daily-plan.sh - 学习计划发送
- quiz-form/ - 考题系统

**工具脚本：**
- validate-configs.sh - 配置验证
- config-manager.sh - 配置管理
- weekly-backup.sh - 每周备份

### 📁 agents/ - Agent 系统 (约 20 个文件)
**review-system/**
- castle-six-analysis-framework.md - 综合分析框架
- castle-six-user-guide.md - 用户指南
- castle-six-*.md - Castle Six 相关文档
- templates/ - 复盘模板
- project-log/ - 项目日志

### 📁 config/ - 配置文件
- active-configs.json - 配置中心
- cron-tasks.json - Cron 任务配置

### 📁 goals/ - 目标与计划
- growth-12week-plan-v5.md - 12 周学习计划
- growth-12week-plan-v4.md - 旧版计划
- growth-12week-plan-complete.md - 完整版
- appendix1-w1-daily-plans.md - 每日计划
- appendix2-answers.md - 考题答案
- targets.md - 目标设定
- health-goals.md - 健康目标

### 📁 daily-output/ - 每日输出
**health/** - 健康堡每日数据
**growth/** - 成长堡每日数据
**total-review/** - 总复盘数据

### 📁 data/ - 数据文件
**strava/** - Strava 运动数据
**total-review/** - 总复盘数据
**analysis/** - 分析数据

### 📁 docs/ - 文档
**openclaw/** - OpenClaw 文档
**skills/** - Skills 文档
**fu-pan-method-guide.md - 复盘方法论

### 📁 memory/ - 记忆文件
- YYYY-MM-DD.md - 每日记录
- heartbeat-state.json - 心跳状态

### 📁 表单系统 (4 套)
**health-form/** - 健康堡表单 (端口 8897)
**growth-form/** - 成长堡表单 (端口 8896)
**quiz-form/** - 考题表单 (端口 8898)
**relationship-form/** - 关系堡表单 (端口 8899)

### 📁 skills/ - 技能文件
**nano-banana-pro/** - 图像生成技能
**agentmail/** - 邮件技能
**agent-browser/** - 浏览器技能
**basename-agent/** - 域名技能
**searxng/** - 搜索技能
**qmd/** - 本地搜索技能
**apple-reminders/** - 提醒事项技能
**mcporter/** - MCP 技能
**skill-9/** - Agent Reach 技能

---

## 📊 归档统计

| 类别 | 目录数 | 文件数 | 总大小 |
|------|--------|--------|--------|
| scripts | 1 | ~30 | ~300 KB |
| agents | 5 | ~50 | ~100 KB |
| config | 1 | ~5 | ~20 KB |
| goals | 1 | ~15 | ~500 KB |
| daily-output | 4 | ~20 | ~100 KB |
| data | 5 | ~30 | ~200 KB |
| docs | 3 | ~20 | ~100 KB |
| memory | 1 | ~10 | ~50 KB |
| 表单系统 | 4 | ~20 | ~100 KB |
| skills | 10 | ~100 | ~1 MB |
| 根目录文档 | 1 | 13 | ~50 KB |
| **总计** | **35+** | **300+** | **~2.5 MB** |

---

## 🔄 更新流程

### 手动归档
```bash
cd /Users/liwang/.openclaw/workspace/OpenClaw-Archive

# 更新文件
git add .
git commit -m "archive: 更新 XXX (YYYY-MM-DD)"
git push origin main
```

### 自动备份（每周日 22:00）
Cron 任务自动执行：
```bash
./scripts/weekly-backup.sh
```
- 备份所有核心配置
- 生成变更日志
- 自动推送到 GitHub

---

## 📝 排除文件 (.gitignore)

以下文件不会上传到 GitHub：
- `node_modules/` - 依赖包（太大）
- `*.log` - 日志文件
- `logs/` - 日志目录
- `*.pdf` - PDF 报告（太大）
- `reports/` - 报告目录
- `.DS_Store` - macOS 系统文件

---

## 🔗 相关链接

- **GitHub 仓库：** https://github.com/liwa5001/OpenClaw-Archive
- **OpenClaw 官方：** https://github.com/openclaw/openclaw
- **官方文档：** https://docs.openclaw.ai
- **技能市场：** https://clawhub.com

---

**🏰 城堡 OpenClaw Archive | 完整备份，安全归档！**
