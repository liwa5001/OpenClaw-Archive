#!/bin/bash
# 健康堡公网穿透启动脚本 (Cloudflare Tunnel)
# 端口：8897

LOG_DIR="/Users/liwang/.openclaw/workspace/logs"
URL_FILE="$LOG_DIR/health-public-url.txt"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 停止旧进程
pkill -f 'cloudflared tunnel --url http://localhost:8897' 2>/dev/null

# 启动 Cloudflare Tunnel
echo "🚀 启动健康堡 Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:8897 > "$LOG_DIR/cloudflared-health.log" 2>&1 &

# 等待 URL 生成
sleep 5

# 提取公网 URL
URL=$(grep -o 'https://[^[:space:]]*trycloudflare[[:space:]]*' "$LOG_DIR/cloudflared-health.log" | head -1 | tr -d '[:space:]')

if [ -n "$URL" ]; then
    echo "$URL" > "$URL_FILE"
    echo "✅ 健康堡公网访问已启动"
    echo " 访问链接：$URL"
    
    # 发送到飞书
    cd /Users/liwang/.openclaw/workspace
    /opt/homebrew/bin/openclaw message send --channel feishu --target ou_7781abd1e83eae23ccf01fe627f0747f " **健康堡公网访问已开启**

👉 **手机访问链接：** [$URL]($URL)

**说明：**
- ✅ 4G/5G/WiFi 都能访问
- ✅ 链接长期有效（除非重启）
- 📊 数据保存在本地：daily-output/health/daily-stats/

**服务器状态：**
- 本地：http://localhost:8897
- 公网：$URL

链接已保存到：logs/health-public-url.txt"
else
    echo "❌ 启动失败，查看日志：logs/cloudflared-health.log"
fi
