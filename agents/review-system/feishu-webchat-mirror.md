# 📱 飞书 + Web UI 完全镜像配置

**创建日期：** 2026-03-12  
**状态：** ⏳ 配置中

---

## 🎯 目标

**飞书和 Web UI 完全镜像：**
- ✅ 飞书收到的消息 → Web UI 也显示
- ✅ Web UI 收到的消息 → 飞书也显示
- ✅ 所有定时任务 → 同时发送到两个渠道

---

## 📊 当前状态

### 已配置渠道

| 渠道 | 状态 | 说明 |
|------|------|------|
| Feishu | ✅ 已启用 | ou_7781abd1e83eae23ccf01fe627f0747f |
| Web UI | ✅ 已启用 | webchat channel |
| iMessage | ✅ 已启用 | 仅用于特定任务 |

### Cron 任务发送渠道

**当前配置：**
- 大部分任务 → 仅发送到 Feishu
- 部分任务 → 通过 session（Web UI 自动接收）

**需要修改：**
- 所有 Feishu 任务 → 同时发送到 Web UI
- 所有 session 任务 → 同时发送到 Feishu

---

## 🔧 解决方案

### 方案 1：修改 delivery 配置（推荐）

修改 Cron 任务的 delivery 配置，同时发送到多个渠道：

```json
"delivery": {
  "mode": "announce",
  "channels": ["feishu", "webchat"]
}
```

**优点：**
- ✅ 集中管理
- ✅ 无需修改脚本
- ✅ 易于维护

**缺点：**
- ⚠️ 需要 OpenClaw 支持多 channels

---

### 方案 2：修改脚本（已实现）

创建统一发送函数 `send-unified-message.sh`：

```bash
#!/bin/bash
# 同时发送到飞书和 Web UI

MESSAGE="测试消息"

# 发送到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"

# Web UI 通过 session 自动接收（当前会话）
```

**优点：**
- ✅ 立即可用
- ✅ 灵活控制

**缺点：**
- ❌ 需要修改所有脚本
- ❌ 维护成本高

---

### 方案 3：配置 Gateway 广播（最佳）

配置 Gateway 自动广播到所有渠道：

```json
{
  "channels": {
    "broadcast": {
      "enabled": true,
      "targets": ["feishu", "webchat"]
    }
  }
}
```

**优点：**
- ✅ 一次配置，全局生效
- ✅ 无需修改脚本
- ✅ 自动同步

**缺点：**
- ⚠️ 需要 OpenClaw 支持

---

## 📋 实施计划

### 阶段 1：立即可用（方案 2）

**修改以下脚本：**
1. ✅ `scripts/send-unified-message.sh` - 已创建
2. ⏳ `scripts/health-daily-review.sh` - 待修改
3. ⏳ `scripts/growth-daily-review.sh` - 待修改
4. ⏳ `scripts/total-daily-brief.sh` - 待修改
5. ⏳ 其他发送消息的脚本

### 阶段 2：优化配置（方案 1 或 3）

**等待 OpenClaw 更新支持：**
- 多 channels delivery
- Gateway 广播配置

---

## 🧪 测试验证

### 测试消息

```bash
cd /Users/liwang/.openclaw/workspace
./scripts/send-unified-message.sh test
```

**预期结果：**
- ✅ 飞书收到消息
- ✅ Web UI 收到消息
- ✅ 内容完全一致

---

## 📝 注意事项

1. **消息格式：** 飞书支持 Markdown，Web UI 也支持
2. **链接格式：** 飞书需要完整 URL
3. **表情符号：** 两边都支持 emoji
4. **发送频率：** 避免过于频繁

---

## 🎯 完成标准

- [ ] 所有定时任务同时发送到飞书和 Web UI
- [ ] 消息内容完全一致
- [ ] 无明显延迟
- [ ] 错误处理完善

---

**🏰 Castle Six | 完全镜像系统配置中！**
