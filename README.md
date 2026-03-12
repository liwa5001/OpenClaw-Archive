# 配置中心

**目的：** 集中管理所有自动化任务的配置，避免配置变更遗漏和混淆

---

## 📁 文件结构

```
config/
├── README.md              # 本文件
├── active-configs.json    # 活跃配置中心
└── deprecated-configs/    # 已停用的配置（归档）
```

---

## 🔧 管理工具

### 查看配置列表

```bash
./scripts/config-manager.sh list
```

### 验证配置状态

```bash
./scripts/config-manager.sh check
# 或
./scripts/validate-configs.sh
```

---

## 📋 配置变更流程

### 添加新任务

1. 编辑 `active-configs.json`，在 `tasks` 中添加新配置
2. 创建对应的脚本文件
3. 运行验证：`./scripts/validate-configs.sh`
4. 添加到 crontab（如需要）
5. 更新 `memory/YYYY-MM-DD.md` 记录变更

### 停用任务

1. 在 `active-configs.json` 中将任务移到 `deprecated` 部分
2. 设置 `"status": "deprecated"`
3. 添加 `deprecatedDate` 和 `reason`
4. 删除或注释相关脚本
5. 从 crontab 移除定时任务
6. 运行验证确认

---

## ⏰ 自动验证

**配置验证任务：** 每天早上 6:55 自动运行

- 在晨报任务（7:00）之前执行
- 检查所有脚本是否存在
- 检查命令路径是否正确
- 检查 crontab 配置
- 日志输出：`logs/config-validation.log`

---

## 📊 当前活跃任务

| 任务 | 时间 | 渠道 | 脚本 |
|------|------|------|------|
| 晨报 | 7:00 | 飞书 | morning-news.sh |
| 健康日报 | 7:30 | 飞书 | health-report.sh |
| 训练提醒（当天） | 8:00 | 飞书 | training-reminder.sh |
| 训练提醒（预告） | 20:00 | 飞书 | training-reminder.sh |
| 运动数据分析 | 9:00 | 飞书 | analyze-workout.sh |
| 训练计划检查 | 9:30 | 飞书 | update-training-plan.sh |
| 健康周报 | 周一 8:30 | 飞书 | health-report.sh |
| 健康年报 | 1 月 1 日 9:00 | 飞书 | health-report.sh |

---

## 🔍 常见问题

### Q: 为什么配置验证在 6:55 而不是 7:00？
A: 在晨报任务之前 5 分钟执行，如果发现问题还有时间修复，避免发送失败。

### Q: 如何查看验证历史？
A: 查看 `logs/config-validation.log`

### Q: crontab 在哪里？
A: 使用 `crontab -l` 查看当前用户的 crontab

---

## 📝 变更记录

| 日期 | 变更 | 原因 |
|------|------|------|
| 2026-03-05 | 创建配置中心 | 避免晨报配置混淆问题 |
| 2026-03-05 | 添加自动验证 | 每天自动检查配置状态 |

---

**维护者：** 城堡 🏰  
**最后更新：** 2026-03-05
