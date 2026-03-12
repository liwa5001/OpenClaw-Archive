# 📁 Castle Six 项目日志 - 文件命名规范

**生效日期：** 2026-03-10  
**维护者：** 城堡 🏰

---

## 📋 统一命名格式

### 日报文件
```
YYYY-MM-DD-castle6-daily.md
YYYY-MM-DD-castle6-daily.pdf
```

**示例：**
- `2026-03-08-castle6-daily.md`
- `2026-03-09-castle6-daily.md`
- `2026-03-10-castle6-daily.md`

---

## 🎯 命名规则说明

| 部分 | 格式 | 说明 |
|------|------|------|
| 日期 | `YYYY-MM-DD` | 年 - 月-日，便于时间排序 |
| 项目名 | `castle6` | 城堡六堡项目标识 |
| 类型 | `daily` | 日报类型（未来可能有 weekly/monthly） |
| 扩展名 | `.md` / `.pdf` | Markdown 源文件 / PDF 导出 |

---

## 📂 目录结构

```
/workspace/agents/review-system/project-log/
├── README.md                      # 本文件（命名规范）
├── 2026-03-08-castle6-daily.md   # 3 月 8 日日报
├── 2026-03-09-castle6-daily.md   # 3 月 9 日日报
├── 2026-03-10-castle6-daily.md   # 3 月 10 日日报
└── pdfs/
    ├── 2026-03-08-castle6-daily.pdf
    ├── 2026-03-09-castle6-daily.pdf
    └── 2026-03-10-castle6-daily.pdf
```

---

## 🔄 历史文件迁移

**迁移日期：** 2026-03-10

| 旧文件名 | 新文件名 |
|---------|---------|
| `2026-03-08-full-conversation.md` | `2026-03-08-castle6-daily.md` |
| `2026-03-09-castle6-log.md` | `2026-03-09-castle6-daily.md` |
| `daily-report-2026-03-09.md` | （已删除，内容合并到主文件） |

---

## 📝 使用脚本

### 生成今日日报
```bash
# 脚本会自动使用正确命名
./scripts/generate-castle6-daily.sh
```

### 批量处理
```bash
# 所有日报文件匹配模式
ls project-log/????-??-??-castle6-daily.md
```

---

## 💡 最佳实践

1. **每日创建** - 每天 22:00 前生成当日日报
2. **PDF 同步** - MD 生成后同时导出 PDF
3. **不要手动命名** - 使用脚本自动生成
4. **定期归档** - 每月打包一次旧文件

---

**下次审查：** 2026-04-10
