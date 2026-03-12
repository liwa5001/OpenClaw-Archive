#!/bin/bash
# 健康堡每日问卷发送脚本
# 每天早上发送 HTML 表单链接到飞书

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/health-form-sender.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"
PORT=8897

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 健康堡问卷发送开始 ==="

# 获取本机 IP（macOS 兼容）
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

# 检查服务器是否运行
if ! curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
    log "服务器未运行，启动健康堡服务器..."
    cd "$WORKSPACE/health-form"
    nohup node server.js > "$WORKSPACE/logs/health-server.log" 2>&1 &
    SERVER_PID=$!
    log "服务器已启动 (PID: $SERVER_PID)"
    sleep 2
fi

# 生成表单链接
FORM_URL="http://${LOCAL_IP}:${PORT}/"

# 获取今天日期
TODAY=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%A')

# 根据星期几生成不同的消息
case "$WEEKDAY" in
    "Monday")
        WEIGHT_NOTE="⚖️ 体重记录：今天是周一，记得填写体重"
        ;;
    *)
        WEIGHT_NOTE="⚖️ 体重记录：仅周一填写"
        ;;
esac

# 发送飞书消息
log "发送飞书消息..."

MESSAGE="💪 健康堡每日问卷 | $TODAY

一天辛苦了！花 2 分钟填写今天的健康数据~

👉 点击填写表单：
$FORM_URL

【填写内容】
🏃 运动训练（Strava 自动同步）
🍽️ 饮食记录（早/午/晚餐 + 夜宵）
😴 睡眠质量（入睡/起床/深睡/浅睡/REM）
$WEIGHT_NOTE

【自动同步】
📊 Strava 运动数据：已加载

提交后立即收到评分和建议！🚀

---
🏰 城堡健康堡 | 科学训练，持续进步！"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"

log "✅ 健康堡问卷已发送"
log "=== 健康堡问卷发送完成 ==="
