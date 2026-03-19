#!/bin/bash
# 启动健康图片收集器（飞书 webhook 服务器）

set -e

cd /Users/liwang/.openclaw/workspace
mkdir -p logs

LOG_FILE="logs/health-image-collector.log"
PID_FILE="logs/health-image-collector.pid"

# 检查是否已在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "✅ 健康图片收集器已在运行 (PID: $OLD_PID)"
        exit 0
    else
        echo "⚠️ 检测到残留 PID 文件，清理中..."
        rm -f "$PID_FILE"
    fi
fi

echo "🚀 启动健康图片收集器..."

# 后台启动
nohup node scripts/health-image-collector.js > "$LOG_FILE" 2>&1 &
NEW_PID=$!

echo $NEW_PID > "$PID_FILE"

sleep 2

# 检查是否启动成功
if ps -p "$NEW_PID" > /dev/null 2>&1; then
    echo "✅ 健康图片收集器已启动 (PID: $NEW_PID)"
    echo "📡 Webhook 端口：8900"
    echo "📝 日志文件：$LOG_FILE"
    echo ""
    echo "💡 使用说明："
    echo "1. 在飞书给 bot 发送图片"
    echo "2. 添加标签：#睡眠 #早餐 #午餐 #晚餐 #体重"
    echo "3. 自动识别并保存数据"
    echo ""
    echo "🛑 停止服务：pkill -f health-image-collector.js"
else
    echo "❌ 启动失败，请检查日志：$LOG_FILE"
    exit 1
fi
