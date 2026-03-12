# OpenClaw Archive 归档清单

**创建日期：** 2026-03-12  
**GitHub:** https://github.com/liwa5001/OpenClaw-Archive  
**维护者：** 城堡 (海皇堡)

---

## 📦 归档内容

### 📁 configs/ - 配置文件

| 文件 | 说明 | 归档日期 |
|------|------|----------|
| active-configs.json | 配置中心 | - |
| cron-tasks.json | Cron 任务配置 | - |

### 📁 scripts/ - 核心脚本

| 文件 | 说明 | 归档日期 |
|------|------|----------|
| morning-news.sh | 晨报发送脚本 | - |
| daily-hot-report-ultimate.sh | 每日爆款日报 | - |
| weather-report.sh | 天气预报脚本 | - |
| health-daily-review.sh | 健康堡每日复盘 | - |
| growth-daily-review.sh | 成长堡每日复盘 | - |
| castle-six-daily-questionnaire.sh | Castle Six 问卷发送 | - |
| total-review-scientific-full.js | 科学总复盘脚本 | 2026-03-12 |
| relationship-weekly-sender.sh | 关系堡每周问卷 | 2026-03-12 |

### 📁 docs/ - 重要文档

| 文件 | 说明 | 归档日期 |
|------|------|----------|
| growth-12week-plan-v5.md | 12 周学习计划 | - |
| castle-six-analysis-framework.md | Castle Six 分析框架 | 2026-03-12 |
| castle-six-user-guide.md | Castle Six 用户指南 | 2026-03-12 |
| castle-six-final-real-record.md | Castle Six 完成记录 | 2026-03-12 |

### 📁 backups/ - 定期备份

| 备份日期 | 内容 | 说明 |
|----------|------|------|
| YYYY-MM-DD | 完整配置备份 | 每周日自动备份 |

---

## 🔄 更新流程

### 手动归档
```bash
cd /Users/liwang/.openclaw/workspace/OpenClaw-Archive

# 复制最新文件
cp ../scripts/total-review-scientific-full.js scripts/
cp ../agents/review-system/castle-six-*.md docs/

# 提交更新
git add .
git commit -m "archive: 更新 XXX (YYYY-MM-DD)"
git push origin main
```

### 自动备份（每周日 22:00）
Cron 任务自动执行 `scripts/weekly-backup.sh`
- 备份所有核心配置到 `backups/YYYY-MM-DD/`
- 生成变更日志
- 自动推送到 GitHub

---

## 📊 归档统计

| 类别 | 文件数 | 总大小 | 最后更新 |
|------|--------|--------|----------|
| configs | 0 | 0 KB | - |
| scripts | 0 | 0 KB | - |
| docs | 0 | 0 KB | - |
| backups | 0 | 0 KB | - |
| **总计** | **0** | **0 KB** | - |

---

## 🔗 相关链接

- **GitHub 仓库:** https://github.com/liwa5001/OpenClaw-Archive
- **OpenClaw 官方:** https://github.com/openclaw/openclaw
- **官方文档:** https://docs.openclaw.ai
- **技能市场:** https://clawhub.com

---

**🏰 城堡 OpenClaw Archive | 安全备份，随时恢复！**
