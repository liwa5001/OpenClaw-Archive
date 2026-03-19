#!/bin/bash

# 有声读本公网穿透启动脚本
# 使用 Cloudflare Tunnel（稳定，URL 长期不变）

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_DIR="$WORKSPACE/logs"
AUDIOBOOK_DIR="$WORKSPACE/audiobook"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

echo "🚀 启动有声读本服务器..."

# 1. 启动 Node.js 服务器（后台）
cd "$AUDIOBOOK_DIR"
pkill -f "node server.js" 2>/dev/null
nohup node server.js > "$LOG_DIR/audiobook-server.log" 2>&1 &
SERVER_PID=$!

echo "✅ 服务器已启动 (PID: $SERVER_PID)"

# 等待服务器就绪
sleep 2

# 2. 启动 Cloudflare Tunnel
echo "🌐 启动 Cloudflare Tunnel..."

pkill -f "cloudflared tunnel --url" 2>/dev/null

nohup cloudflared tunnel --url http://localhost:8895 > "$LOG_DIR/cloudflared-audiobook.log" 2>&1 &
TUNNEL_PID=$!

echo "✅ Tunnel 已启动 (PID: $TUNNEL_PID)"

# 等待 Tunnel 就绪并获取 URL
sleep 3

# 提取公网 URL
PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$LOG_DIR/cloudflared-audiobook.log" | head -1)

if [ -z "$PUBLIC_URL" ]; then
    echo "⏳ 等待 Tunnel 连接..."
    sleep 5
    PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$LOG_DIR/cloudflared-audiobook.log" | head -1)
fi

if [ -n "$PUBLIC_URL" ]; then
    echo "$PUBLIC_URL" > "$LOG_DIR/audiobook-public-url.txt"
    echo ""
    echo "=========================================="
    echo "📚 有声读本已就绪！"
    echo "=========================================="
    echo "🌐 公网链接：$PUBLIC_URL"
    echo "📱 手机/电脑都能访问"
    echo "💾 链接已保存：$LOG_DIR/audiobook-public-url.txt"
    echo ""
    echo "📋 管理命令："
    echo "  查看链接：cat $LOG_DIR/audiobook-public-url.txt"
    echo "  查看日志：tail -f $LOG_DIR/audiobook-server.log"
    echo "  停止服务：pkill -f 'node server.js' && pkill -f 'cloudflared tunnel'"
    echo "=========================================="
else
    echo "⚠️  未能获取公网 URL，请检查日志：$LOG_DIR/cloudflared-audiobook.log"
fi
