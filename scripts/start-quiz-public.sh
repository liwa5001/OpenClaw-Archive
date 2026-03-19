#!/bin/bash
# 启动考题服务器 + 公网穿透（Cloudflare Tunnel）

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_DIR="$WORKSPACE/logs"
URL_FILE="$LOG_DIR/quiz-public-url.txt"
PORT=8898

echo "🚀 启动考题服务器 + Cloudflare Tunnel..."

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 1. 启动考题服务器
echo "📝 启动考题服务器 (端口 $PORT)..."
cd "$WORKSPACE/quiz-form"

# 先停止旧的服务器进程
pkill -f "quiz-form.*server.js" 2>/dev/null || true
sleep 1

# 启动新的服务器
nohup node server.js > "$LOG_DIR/quiz-server.log" 2>&1 &
sleep 2

if curl -s http://localhost:$PORT/ > /dev/null 2>&1; then
    echo "✅ 考题服务器已启动"
else
    echo "❌ 考题服务器启动失败"
    exit 1
fi

# 2. 启动 Cloudflare Tunnel
echo "🌐 启动 Cloudflare Tunnel..."

# 先停止旧的 tunnel
pkill -f "cloudflared tunnel --url http://localhost:$PORT" 2>/dev/null || true
sleep 1

# 启动新的 tunnel（后台运行）
nohup cloudflared tunnel --url http://localhost:$PORT > "$LOG_DIR/cloudflared-quiz.log" 2>&1 &

# 等待 tunnel 启动并获取 URL
echo "⏳ 等待 Tunnel 就绪..."
sleep 5

# 提取公网 URL
for i in {1..10}; do
    PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$LOG_DIR/cloudflared-quiz.log" | tail -1)
    if [ -n "$PUBLIC_URL" ]; then
        break
    fi
    sleep 1
done

if [ -z "$PUBLIC_URL" ]; then
    echo "⚠️ 未检测到公网 URL，等待更长时间..."
    sleep 5
    PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$LOG_DIR/cloudflared-quiz.log" | tail -1)
fi

if [ -n "$PUBLIC_URL" ]; then
    echo "$PUBLIC_URL" > "$URL_FILE"
    echo ""
    echo "✅ 考题公网访问已就绪！"
    echo ""
    echo "🌐 公网链接：$PUBLIC_URL"
    echo "📁 链接已保存到：$URL_FILE"
    echo ""
    echo "💡 使用方法："
    echo "   - 手机/电脑任意网络都能访问"
    echo "   - 链接长期有效（除非重启）"
    echo ""
    echo "📋 查看链接：cat $URL_FILE"
    echo "🛑 停止服务：pkill -f 'cloudflared tunnel' && pkill -f 'quiz-form.*server.js'"
else
    echo "❌ Tunnel 启动失败，请查看日志：$LOG_DIR/cloudflared-quiz.log"
    exit 1
fi
