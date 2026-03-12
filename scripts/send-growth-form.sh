#!/bin/bash
# 成长堡每日问卷发送脚本
# 每天早上发送 HTML 表单链接到飞书

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/growth-form-sender.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"
PORT=8896

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 成长堡问卷发送开始 ==="

# 获取本机 IP（macOS 兼容）
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

# 检查服务器是否运行
if ! curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
    log "服务器未运行，启动成长堡服务器..."
    cd "$WORKSPACE/growth-form"
    nohup node server.js > "$WORKSPACE/logs/growth-server.log" 2>&1 &
    SERVER_PID=$!
    log "服务器已启动 (PID: $SERVER_PID)"
    sleep 2
fi

# 生成表单链接
FORM_URL="http://${LOCAL_IP}:${PORT}/"

# 获取今天日期
TODAY=$(date '+%Y-%m-%d')

# 计算 12 周计划进度
START_DATE="2026-03-10"
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s 2>/dev/null || date -d "$START_DATE" +%s 2>/dev/null || echo "1773091200")
NOW_TS=$(date +%s)
DAYS_ELAPSED=$(( (NOW_TS - START_TS) / 86400 ))
WEEK_NUM=$(( DAYS_ELAPSED / 7 + 1 ))
DAY_NUM=$(( DAYS_ELAPSED % 7 + 1 ))

# 发送飞书消息
log "发送飞书消息..."

MESSAGE="📚 成长堡每日复盘 | $TODAY

12 周计划：第${WEEK_NUM}周 第${DAY_NUM}天

花 3 分钟回顾今天的学习和成长~

👉 点击填写表单：
$FORM_URL

【填写内容】
📖 今日学习（OpenClaw/Claude AI/视频制作）
⭐ 学习质量自评（1-5 分）
📝 今日产出（笔记/实操/作品）
💡 问题与明日计划

【特色功能】
📅 可补填历史数据
📊 自动计算周进度
💬 提交后收到建议

---
🏰 城堡成长堡 | 持续学习，日拱一卒！"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"

log "✅ 成长堡问卷已发送"
log "=== 成长堡问卷发送完成 ==="
