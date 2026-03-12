# 🏰 城堡 - 快速参考卡

**最后更新：** 2026-03-05  
**每次会话开始前必读！**

---

## ⚙️ 活跃任务清单

| 时间 | 任务 | 渠道 | 脚本 | 状态 |
|------|------|------|------|------|
| 6:55 | 配置验证 | 日志 | validate-configs.sh | ✅ |
| 7:00 | 晨报 | 飞书 | morning-news.sh | ✅ |
| 7:30 | 健康日报 | 飞书 | health-report.sh | ✅ |
| 8:00 | 训练提醒（当天） | 飞书 | training-reminder.sh | ✅ |
| 9:00 | 运动数据分析 | 飞书 | analyze-workout.sh | ✅ |
| 9:30 | 训练计划检查 | 飞书 | update-training-plan.sh | ✅ |
| 20:00 | 训练提醒（预告） | 飞书 | training-reminder.sh | ✅ |

**周报/年报：**
- 健康周报：周一 8:30
- 健康年报：1 月 1 日 9:00

---

## 🔑 关键配置（必须记住）

### 飞书配置
- **用户 ID：** `ou_7781abd1e83eae23ccf01fe627f0747f`
- **发送格式：** Markdown 链接 `[标题](链接)`
- **澎湃新闻：** 下划线必须编码 `_` → `%5F`

### 命令路径（cron 环境必需）
```bash
openclaw  → /opt/homebrew/bin/openclaw
node      → /opt/homebrew/bin/node
```

### 工作区路径
```
/Users/liwang/.openclaw/workspace
```

---

## ⚠️ 已停用/删除的配置

| 配置 | 停用日期 | 替代方案 |
|------|----------|----------|
| iMessage 晨报 | 2026-03-04 | 飞书晨报 |
| morning-news-ai.js | 2026-03-05 | morning-news.sh |

**重要：** 如果看到任何 iMessage 相关的晨报脚本，应该删除！

---

## 🔧 配置变更流程（CHECKLIST.md）

修改配置前：
1. [ ] `grep -r "关键词" scripts/ memory/` 搜索相关文件
2. [ ] 列出所有相关文件
3. [ ] 确认是否有旧配置需要清理

修改配置后：
1. [ ] 更新主要配置文件
2. [ ] 删除或注释旧配置
3. [ ] 更新 memory/YYYY-MM-DD.md
4. [ ] 验证命令路径（`which 命令`）
5. [ ] 手动测试一次
6. [ ] 记录验证结果

**验证命令：**
```bash
./scripts/validate-configs.sh
```

---

## 📚 重要文档位置

| 文档 | 路径 | 用途 |
|------|------|------|
| 配置中心 | `config/active-configs.json` | 所有活跃配置 |
| 配置 README | `config/README.md` | 配置使用说明 |
| 变更清单 | `CHECKLIST.md` | 配置变更流程 |
| 长期记忆 | `MEMORY.md` | 重要决策记录 |
| 每日记录 | `memory/YYYY-MM-DD.md` | 日常详细日志 |
| 心跳配置 | `HEARTBEAT.md` | 定时任务配置 |

---

## 🚨 常见问题处理

### Q: 晨报没收到怎么办？
1. 检查日志：`cat logs/morning-news.log | tail -20`
2. 运行验证：`./scripts/validate-configs.sh`
3. 检查 crontab：`crontab -l | grep morning`

### Q: 配置冲突/重复发送？
1. 搜索相关脚本：`ls scripts/*morning*`
2. 检查配置中心：`cat config/active-configs.json`
3. 删除旧脚本，更新配置中心

### Q: cron 任务不执行？
1. 检查命令路径是否完整（使用 `which 命令`）
2. 检查脚本执行权限：`chmod +x scripts/xxx.sh`
3. 查看 cron 日志：`grep CRON /var/log/system.log`

---

## 💡 会话开始前检查

- [ ] 已阅读本快速参考卡
- [ ] 已阅读 SOUL.md（我是谁）
- [ ] 已阅读 USER.md（用户信息）
- [ ] 已检查今日记忆（memory/YYYY-MM-DD.md）
- [ ] 如在主会话，已阅读 MEMORY.md

---

**维护者：** 城堡 🏰  
**下次审查：** 每次配置变更时更新此卡片
