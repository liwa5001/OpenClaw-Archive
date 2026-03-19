#!/bin/bash
# 飞书 ↔ Webchat 镜像系统启动脚本（Cloudflared 稳定版）
# 使用 Cloudflare Tunnel 提供稳定的公网穿透

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_DIR="$WORKSPACE/logs"
PORT=8899

echo "🏰 飞书 ↔ Webchat 镜像系统启动（Cloudflared 稳定版）"
echo "=========================================="

# 创建日志目录
mkdir -p "$LOG_DIR"

# 停止旧进程
echo "🛑 停止旧进程..."
pkill -f "feishu-webhook-server-v2" 2>/dev/null || true
pkill -f "cloudflared tunnel" 2>/dev/null || true
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

# 启动 Cloudflared
echo "🌐 启动 Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:$PORT >> "$LOG_DIR/cloudflared-feishu.log" 2>&1 &
CF_PID=$!
echo "✅ Cloudflared PID: $CF_PID"

# 等待穿透完成
sleep 8

# 获取公网 URL
PUBLIC_URL=$(tail -30 "$LOG_DIR/cloudflared-feishu.log" 2>/dev/null | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com" | head -1)

if [ -z "$PUBLIC_URL" ]; then
    echo "❌ Cloudflared 启动失败，未获取到 URL"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ 镜像系统启动完成！"
echo "=========================================="
echo ""
echo "📊 本地状态：http://localhost:$PORT/status"
echo "🌐 公网 URL: $PUBLIC_URL"
echo ""
echo "📋 飞书后台配置步骤："
echo "1. 登录 https://open.feishu.cn/app"
echo "2. 进入「事件与回调」→「回调配置」"
echo "3. 订阅地址：$PUBLIC_URL/feishu/webhook"
echo "4. 订阅事件：im.message.receive_v1"
echo ""
echo "📋 查看日志："
echo "  tail -f $LOG_DIR/feishu-webhook.log"
echo "  tail -f $LOG_DIR/cloudflared-feishu.log"
echo ""
echo "🛑 停止服务："
echo "  pkill -f feishu-webhook-server-v2"
echo "  pkill -f 'cloudflared tunnel'"
echo ""

# 保存当前 URL 到文件
echo "$PUBLIC_URL" > "$LOG_DIR/feishu-mirror-url.txt"
echo "💾 URL 已保存到：$LOG_DIR/feishu-mirror-url.txt"
