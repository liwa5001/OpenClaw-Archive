#!/bin/bash

# 💰 财富堡每日检查
# 启动财富堡服务器并发送飞书消息

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/wealth-daily-check.log"
SERVER_LOG="$WORKSPACE/logs/wealth-server.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"
PORT=8898

# 确保日志目录存在
mkdir -p "$WORKSPACE/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 财富堡每日检查开始 ==="

# 检查服务器是否已在运行
if curl -s http://localhost:$PORT/status > /dev/null 2>&1; then
    log "✅ 财富堡服务器已在运行 (端口 $PORT)"
else
    log "🚀 启动财富堡服务器..."
    
    # 启动服务器
    cd "$WORKSPACE/wealth-form"
    nohup node server.js > "$SERVER_LOG" 2>&1 &
    
    sleep 2
    
    if curl -s http://localhost:$PORT/status > /dev/null 2>&1; then
        log "✅ 财富堡服务器已启动 (端口 $PORT)"
    else
        log "❌ 财富堡服务器启动失败"
        exit 1
    fi
fi

# 获取本机 IP（macOS 兼容，使用 Node.js）
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")
WEALTH_URL="http://${LOCAL_IP}:${PORT}"

log "💰 财富堡访问地址：$WEALTH_URL"

# 获取公网链接
PUBLIC_URL_FILE="$WORKSPACE/logs/wealth-public-url.txt"
if [ -f "$PUBLIC_URL_FILE" ]; then
    PUBLIC_URL=$(cat "$PUBLIC_URL_FILE")
else
    PUBLIC_URL="http://localhost:${PORT}"
fi

# 发送飞书消息
log "📨 发送飞书消息..."

MESSAGE="💰 财富堡每日追踪

📊 记录每日收支，掌控财务自由之路

👉 点击填写表单：$PUBLIC_URL

**填写内容：**
- 💸 今日收支记录
- 🏦 账户余额
- 🎯 储蓄目标进度
- 💭 财务反思

---
🏰 Castle Six | 财富堡"

# 使用 openclaw message 发送
cd "$WORKSPACE"
/opt/homebrew/bin/openclaw message send \
    --channel feishu \
    --target "$FEISHU_USER" \
    --message "$MESSAGE" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "✅ 飞书消息发送成功"
else
    log "❌ 飞书消息发送失败"
fi

log "=== 财富堡每日检查完成 ==="
log ""
