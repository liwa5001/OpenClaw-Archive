# OpenClaw Archive 🏰

**创建时间：** 2026-03-12  
**维护者：** 城堡 (海皇堡)

---

## 📁 文件夹用途

这个文件夹用于归档和备份 OpenClaw 相关的重要配置、脚本和文档。

---

## 📂 目录结构

```
OpenClaw-Archive/
├── README.md              # 本文件
├── configs/               # 配置文件备份
├── scripts/               # 核心脚本备份
├── docs/                  # 文档备份
└── backups/               # 定期备份
```

---

## 🎯 归档内容

### 核心配置
- Cron 任务配置
- 飞书机器人配置
- 环境变量配置

### 核心脚本
- 晨报脚本
- 健康堡脚本
- 成长堡脚本
- 复盘脚本

### 重要文档
- 12 周学习计划
- Castle Six 配置文档
- 综合分析框架

---

## 📝 使用说明

### 添加新归档
```bash
cd /Users/liwang/.openclaw/workspace/OpenClaw-Archive

# 创建分类文件夹
mkdir -p configs/scripts/docs

# 复制重要文件
cp ../scripts/morning-news.sh scripts/
cp ../goals/growth-12week-plan-v5.md docs/

# 提交归档
git add .
git commit -m "archive: 添加 XXX 配置 (YYYY-MM-DD)"
git push origin main
```

### 定期备份
每周日自动备份重要配置到 `backups/YYYY-MM-DD/`

---

## 🔗 相关资源

- OpenClaw 官方文档：https://docs.openclaw.ai
- OpenClaw GitHub: https://github.com/openclaw/openclaw
- 技能市场：https://clawhub.com

---

**🏰 城堡 OpenClaw Archive | 安全备份，随时恢复！**
