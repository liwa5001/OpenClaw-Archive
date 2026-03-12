#!/bin/bash
# 关系堡每周问卷发送脚本
# 每周日 20:00 发送关系堡 HTML 问卷

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/relationship-weekly-sender.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 关系堡每周问卷发送开始 ==="

# 获取本机 IP
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

TODAY=$(date '+%Y-%m-%d')

# 计算周数
START_DATE="2026-03-10"
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s 2>/dev/null || echo "1773091200")
NOW_TS=$(date +%s)
DAYS_ELAPSED=$(( (NOW_TS - START_TS) / 86400 ))
WEEK_NUM=$(( DAYS_ELAPSED / 7 + 1 ))

# 检查并启动服务器
if ! curl -s "http://localhost:8899" > /dev/null 2>&1; then
    log "启动关系堡服务器..."
    cd "$WORKSPACE/relationship-form"
    nohup node server.js > "$WORKSPACE/logs/relationship-server.log" 2>&1 &
    sleep 2
    log "✅ 关系堡服务器已启动"
else
    log "关系堡服务器已运行"
fi

# 发送飞书消息
log "发送关系堡问卷..."

MESSAGE="💕 **关系堡每周问卷 | 第${WEEK_NUM}周**

花 5 分钟回顾本周的关系状态~

👉 http://${LOCAL_IP}:8899/

【填写内容】
💕 爱情关系（亲密感/沟通/支持/信任）
👨‍👩‍👦 家庭关系（聚会/沟通/活动）
🤝 社交关系（新朋友/老友/活动/能量）
📊 本周总结（收获 + 目标）

【说明】
- 每周日晚填写一次
- 记录真实感受
- 提交后收到反馈和建议

---
💕 城堡关系堡 | 用心经营，关系和谐！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"
log "✅ 关系堡问卷已发送"
log "=== 关系堡每周问卷发送完成 ==="
