#!/bin/bash
# 健康堡每日问卷发送脚本
# 每天早上 8:00 发送健康堡 HTML 问卷

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/health-daily-questionnaire.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 健康堡每日问卷发送开始 ==="

# 同步 Strava 数据
log "🔄 同步 Strava 数据..."
cd "$WORKSPACE" && ./scripts/sync-strava-data.sh >> "$LOG_FILE" 2>&1 || log "⚠️ Strava 同步失败"

# 获取本机 IP
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

TODAY=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')

# 根据星期几生成体重提示
if [ "$WEEKDAY" -eq 1 ]; then
    WEIGHT_NOTE="⚖️ 体重记录：今天是周一，记得填写体重"
else
    WEIGHT_NOTE="⚖️ 体重记录：仅周一填写"
fi

# 检查并启动服务器
if ! curl -s "http://localhost:8897" > /dev/null 2>&1; then
    log "启动健康堡服务器..."
    cd "$WORKSPACE/health-form"
    nohup node server.js > "$WORKSPACE/logs/health-server.log" 2>&1 &
    sleep 2
    log "✅ 健康堡服务器已启动"
else
    log "健康堡服务器已运行"
fi

# 发送飞书消息
log "发送健康堡问卷..."

MESSAGE="💪 **健康堡每日问卷 | $TODAY**

花 2 分钟填写健康数据~

👉 http://${LOCAL_IP}:8897/

【填写内容】
🏃 运动训练（Strava 自动同步）
🍽️ 饮食记录（早/午/晚餐 + 夜宵）
😴 睡眠质量（入睡/起床/深睡/浅睡/REM）
$WEIGHT_NOTE

【自动同步】
📊 Strava 运动数据：已加载

提交后立即收到评分和建议！🚀

---
🏰 城堡健康堡 | 科学训练，持续进步！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"
log "✅ 健康堡问卷已发送"
log "=== 健康堡每日问卷发送完成 ==="
