#!/bin/bash
# 飞书 ↔ Webchat 镜像系统启动脚本
# 一键启动 webhook 服务器 + localtunnel 穿透

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_DIR="$WORKSPACE/logs"
PORT=8899

echo "🏰 飞书 ↔ Webchat 镜像系统启动"
echo "=========================================="

# 创建日志目录
mkdir -p "$LOG_DIR"

# 停止旧进程
echo "🛑 停止旧进程..."
pkill -f "feishu-webhook-server-v2" 2>/dev/null || true
pkill -f "lt --port $PORT" 2>/dev/null || true
sleep 1

# 启动 webhook 服务器
echo "🚀 启动 Webhook 服务器 (端口 $PORT)..."
cd "$WORKSPACE"
node scripts/feishu-webhook-server-v2.js >> "$LOG_DIR/feishu-webhook.log" 2>&1 &
WEBHOOK_PID=$!
echo "✅ Webhook 服务器 PID: $WEBHOOK_PID"

# 等待服务器启动
sleep 2

# 检查服务器状态
if curl -s "http://localhost:$PORT/status" > /dev/null 2>&1; then
    echo "✅ Webhook 服务器运行正常"
else
    echo "❌ Webhook 服务器启动失败"
    exit 1
fi

# 启动 localtunnel
echo "🌐 启动 Localtunnel 穿透..."
lt --port $PORT --subdomain feishu-mirror >> "$LOG_DIR/lt-feishu-webhook.log" 2>&1 &
LT_PID=$!
echo "✅ Localtunnel PID: $LT_PID"

# 等待穿透完成
sleep 5

# 获取公网 URL
PUBLIC_URL=$(tail -1 "$LOG_DIR/lt-feishu-webhook.log" | grep -oE "https://[a-zA-Z0-9.-]+\.loca\.lt" || echo "获取失败")

echo ""
echo "=========================================="
echo "✅ 镜像系统启动完成！"
echo "=========================================="
echo ""
echo "📊 本地状态：http://localhost:$PORT/status"
echo "🌐 公网 URL: $PUBLIC_URL"
echo ""
echo "📝 飞书后台配置步骤："
echo "1. 登录 https://open.feishu.cn/app"
echo "2. 进入「事件订阅」页面"
echo "3. 订阅地址：$PUBLIC_URL/feishu/webhook"
echo "4. 订阅事件：im.message.receive_v1"
echo ""
echo "📋 查看日志："
echo "  tail -f $LOG_DIR/feishu-webhook.log"
echo "  tail -f $LOG_DIR/lt-feishu-webhook.log"
echo ""
echo "🛑 停止服务："
echo "  pkill -f feishu-webhook-server-v2"
echo "  pkill -f 'lt --port $PORT'"
echo ""
