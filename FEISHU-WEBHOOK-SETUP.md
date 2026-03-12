# 📨 飞书 Webhook 双向同步配置指南

## 目标
实现飞书 ↔ Webchat 双向消息同步：
- 飞书收到消息 → 自动转发到 Webchat
- Webchat 收到消息 → 自动转发到飞书

---

## 方案一：飞书开放平台事件订阅（推荐）

### 步骤 1：创建飞书应用

1. 访问 [飞书开放平台](https://open.feishu.cn/app)
2. 点击"创建企业自建应用"
3. 填写应用名称（如：OpenClaw 消息同步）
4. 进入应用管理页面

### 步骤 2：配置权限

在"权限管理"页面添加以下权限：
- `im:message` - 读取和发送消息
- `im:chat` - 读取聊天信息
- `contact:user.base:readonly` - 读取用户信息

### 步骤 3：配置事件订阅

1. 进入"事件订阅"页面
2. 开启"启用事件订阅"
3. 填写请求地址（需要公网可访问）：
   ```
   https://your-domain.com/feishu/webhook
   ```
4. 复制 Verification Token（填入 `config/feishu-webhook-config.json`）
5. 复制 Encrypt Key（如果需要加密）

**订阅的事件类型：**
- `im.message.receive_v1` - 收到消息
- `im.message.read_v1` - 消息已读（可选）

### 步骤 4：配置机器人

1. 进入"机器人"页面
2. 添加机器人能力
3. 配置机器人头像和名称
4. 在"消息接收设置"中：
   - 开启"接收消息"
   - 选择"单聊"和/或"群聊"

### 步骤 5：发布应用

1. 进入"版本管理与发布"
2. 创建新版本
3. 提交审核（企业自建应用通常自动通过）
4. 发布后，在飞书中搜索并添加该机器人

---

## 方案二：使用 ngrok 内网穿透（测试用）

如果不想配置公网域名，可以用 ngrok 临时暴露本地服务：

```bash
# 安装 ngrok
brew install ngrok

# 启动 webhook 服务器
node /Users/liwang/.openclaw/workspace/scripts/feishu-webhook-server.js &

# 暴露本地端口到公网
ngrok http 8888
```

ngrok 会给你一个临时公网 URL，如：
```
https://abc123.ngrok.io
```

把这个 URL 填到飞书开放平台的事件订阅地址：
```
https://abc123.ngrok.io/feishu/webhook
```

---

## 启动 Webhook 服务器

### 手动启动
```bash
node /Users/liwang/.openclaw/workspace/scripts/feishu-webhook-server.js
```

### 后台运行（推荐）
```bash
nohup node /Users/liwang/.openclaw/workspace/scripts/feishu-webhook-server.js >> logs/feishu-webhook.log 2>&1 &
```

### 查看日志
```bash
tail -f /Users/liwang/.openclaw/workspace/logs/feishu-webhook.log
```

---

## 配置文件

编辑 `/workspace/config/feishu-webhook-config.json`：

```json
{
  "webhook": {
    "enabled": true,
    "port": 8888,
    "path": "/feishu/webhook",
    "verifyToken": "从飞书开放平台复制",
    "encryptKey": "从飞书开放平台复制（可选）"
  },
  "sync": {
    "feishuToWebchat": true,
    "webchatToFeishu": true,
    "targetFeishuUser": "ou_7781abd1e83eae23ccf01fe627f0747f"
  }
}
```

---

## 验证配置

1. 启动 webhook 服务器
2. 在飞书开放平台点击"验证"按钮
3. 验证成功后，订阅状态变为"已订阅"
4. 在飞书给机器人发消息
5. 检查 webchat 是否收到转发消息
6. 查看日志确认：`tail -f logs/feishu-webhook.log`

---

## 故障排查

### Q: 飞书验证失败
- 检查 verifyToken 是否正确配置
- 检查服务器是否正常运行
- 检查防火墙/网络是否开放端口

### Q: 消息没有转发
- 检查日志：`logs/feishu-webhook.log`
- 确认机器人已添加到聊天
- 确认事件订阅已开启

### Q: 端口被占用
- 修改配置文件中的端口号
- 或关闭占用端口的进程：`lsof -i :8888`

---

## 下一步

配置完成后，告诉我，我帮你：
1. 启动 webhook 服务器
2. 测试双向同步
3. 配置开机自启动

---

**维护者：** 城堡 🏰  
**最后更新：** 2026-03-07
