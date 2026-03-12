# 🏰 Castle Six 每日问卷发送保障文档

**创建日期：** 2026-03-12  
**目的：** 确保每天早上 8:00 自动发送 HTML 问卷链接

---

## ✅ 已配置完成

### 1. Cron 定时任务

**任务 ID：** `434aa838-72ec-46b9-aaed-1f2719e56fd4`  
**任务名称：** 🏰 Castle Six 每日问卷发送  
**执行时间：** 每天早上 8:00 (Asia/Shanghai)  
**Cron 表达式：** `0 8 * * *`

**验证命令：**
```bash
openclaw cron list | grep "Castle Six"
```

---

### 2. 发送脚本

**脚本路径：** `/Users/liwang/.openclaw/workspace/scripts/castle-six-daily-questionnaire.sh`

**功能：**
- ✅ 自动获取当前网络 IP（动态，避免硬编码）
- ✅ 自动启动健康堡服务器（8897）
- ✅ 自动启动成长堡服务器（8896）
- ✅ 发送飞书消息包含两个表单链接
- ✅ 记录日志到 `logs/castle-six-sender.log`

**关键代码（动态获取 IP）：**
```bash
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")
```

---

### 3. HTML 表单

**健康堡：**
- 文件：`/Users/liwang/.openclaw/workspace/health-form/index.html`
- 服务器：`/Users/liwang/.openclaw/workspace/health-form/server.js`
- 端口：8897
- 提交地址：相对路径 `/submit`（自动适配）

**成长堡：**
- 文件：`Users/liwang/.openclaw/workspace/growth-form/index.html`
- 服务器：`/Users/liwang/.openclaw/workspace/growth-form/server.js`
- 端口：8896
- 提交地址：相对路径 `/submit`（自动适配）

**最新改进（2026-03-12）：**
- ✅ 睡眠时长改为小时：分钟格式（如 2:30）
- ✅ 提交地址使用相对路径，自动适配网络

---

## 📋 每日发送内容

### 健康堡问卷消息

```
💪 健康堡每日问卷 | 2026-03-13

一天辛苦了！花 2 分钟填写今天的健康数据~

👉 点击填写表单：
http://192.168.x.x:8897/

【填写内容】
🏃 运动训练（Strava 自动同步）
🍽️ 饮食记录（早/午/晚餐 + 夜宵）
😴 睡眠质量（入睡/起床/深睡/浅睡/REM）
⚖️ 体重记录：仅周一填写（周一时显示）

【自动同步】
📊 Strava 运动数据：已加载

提交后立即收到评分和建议！🚀

---
🏰 城堡健康堡 | 科学训练，持续进步！
```

### 成长堡问卷消息

```
📚 成长堡每日复盘 | 2026-03-13

12 周计划：第 1 周 第 4 天

花 3 分钟回顾今天的学习和成长~

👉 点击填写表单：
http://192.168.x.x:8896/

【填写内容】
📖 今日学习（OpenClaw/Claude AI/视频制作）
⭐ 学习质量自评（1-5 分）
📝 今日产出（笔记/实操/作品）
💡 问题与明日计划

【特色功能】
📅 可补填历史数据
📊 自动计算周进度
💬 提交后收到建议

---
🏰 城堡成长堡 | 持续学习，日拱一卒！
```

---

## 🔧 故障排查

### 问题 1：没有收到飞书消息

**检查日志：**
```bash
tail -20 /Users/liwang/.openclaw/workspace/logs/castle-six-sender.log
```

**手动运行脚本：**
```bash
cd /Users/liwang/.openclaw/workspace && ./scripts/castle-six-daily-questionnaire.sh
```

**检查 cron 状态：**
```bash
openclaw cron list | grep "Castle Six"
```

---

### 问题 2：表单链接打不开

**检查服务器是否运行：**
```bash
curl -s http://localhost:8897 | head -5
curl -s http://localhost:8896 | head -5
```

**手动启动服务器：**
```bash
# 健康堡
cd /Users/liwang/.openclaw/workspace/health-form && node server.js &

# 成长堡
cd /Users/liwang/.openclaw/workspace/growth-form && node server.js &
```

**查看服务器日志：**
```bash
tail -10 /Users/liwang/.openclaw/workspace/logs/health-server.log
tail -10 /Users/liwang/.openclaw/workspace/logs/growth-server.log
```

---

### 问题 3：表单提交失败

**检查提交地址：**
- 必须是相对路径 `/submit`，不能硬编码 IP
- 检查 HTML 文件第 565 行附近

**验证代码：**
```bash
grep -n "fetch.*submit" /Users/liwang/.openclaw/workspace/health-form/index.html
# 应该显示：fetch('/submit', {
```

**检查服务器接收：**
```bash
tail -f /Users/liwang/.openclaw/workspace/logs/health-form.log
```

---

## 📊 日志位置

| 日志文件 | 路径 | 用途 |
|---------|------|------|
| 发送日志 | `logs/castle-six-sender.log` | 记录每日发送状态 |
| 健康堡服务器 | `logs/health-server.log` | 服务器启动/运行日志 |
| 成长堡服务器 | `logs/growth-server.log` | 服务器启动/运行日志 |
| 健康堡表单 | `logs/health-form.log` | 表单提交记录 |
| 成长堡表单 | `logs/growth-form.log` | 表单提交记录 |

---

## ✅ 验证清单（每天 8:05 检查）

- [ ] 飞书收到健康堡问卷消息
- [ ] 飞书收到成长堡问卷消息
- [ ] 链接可以正常打开
- [ ] 表单可以正常提交
- [ ] 提交后收到飞书确认消息

---

## 📝 重要配置记录

### 2026-03-12：修复提交地址硬编码问题

**问题：** 表单提交地址硬编码了旧 IP `172.20.10.2`

**修复：**
- 健康堡：`http://172.20.10.2:8897/submit` → `/submit`
- 成长堡：`http://172.20.10.2:8896/submit` → `/submit`

**教训：**
- 永远不要硬编码 IP 地址
- 使用相对路径自动适配网络变化

---

### 2026-03-12：修复睡眠时长输入格式

**问题：** 睡眠时长用小数表示（如 1.5 小时），不方便输入

**修复：**
- 改为小时：分钟格式（如 1:30）
- JavaScript 自动合并为总小时数发送给服务器

---

## 🎯 明日验证（2026-03-13）

**时间：** 早上 8:05  
**检查项：**
1. ✅ 飞书收到两条问卷消息
2. ✅ 链接可以正常打开
3. ✅ 表单字段正确（特别是睡眠时长格式）
4. ✅ 提交后收到确认

**如果失败：**
1. 查看 `logs/castle-six-sender.log`
2. 手动运行脚本测试
3. 检查 Gateway 是否正常运行

---

## 🔗 相关文件

- 发送脚本：`scripts/castle-six-daily-questionnaire.sh`
- Cron 配置：任务 ID `434aa838-72ec-46b9-aaed-1f2719e56fd4`
- 配置文档：`HEARTBEAT.md`（Castle Six HTML 表单问卷章节）
- 教训记录：`SOUL.md`（Castle Six HTML 表单每日自动发送）
- 自检脚本：`scripts/check-castle-six.sh`

---

**维护者：** 城堡 🏰  
**最后更新：** 2026-03-12 16:01  
**下次验证：** 2026-03-13 08:05

---

**🏰 Castle Six | 自动化保障，万无一失！**
