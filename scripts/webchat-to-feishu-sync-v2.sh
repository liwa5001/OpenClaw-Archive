#!/bin/bash
# Webchat → 飞书 消息同步脚本 v2（简化版）
# 每分钟轮询 session 历史，转发用户新消息到飞书

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/webchat-to-feishu.log"
STATE_FILE="$WORKSPACE/memory/webchat-mirror-state.json"
OPENCLAW_CMD="/opt/homebrew/bin/openclaw"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 初始化
mkdir -p "$(dirname "$STATE_FILE")"
if [ ! -f "$STATE_FILE" ]; then
    echo '{"lastCheck": 0}' > "$STATE_FILE"
fi

log "=== 同步开始 ==="

# 获取最近 5 条消息
messages=$($OPENCLAW_CMD sessions list --limit 1 --json 2>/dev/null)
if [ -z "$messages" ] || [ "$messages" = "[]" ]; then
    log "⚠️ 无活跃 session"
    exit 0
fi

session_id=$(echo "$messages" | node -e "const d=JSON.parse(require('fs').readFileSync(0)); console.log(d[0]?.id||'')" 2>/dev/null || echo "")
if [ -z "$session_id" ]; then
    log "⚠️ 无法获取 session ID"
    exit 0
fi

log "Session: $session_id"

# 获取最后检查时间
last_check=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$STATE_FILE')).lastCheck || 0)")

# 获取 session 历史
history=$($OPENCLAW_CMD sessions history --sessionKey "$session_id" --limit 5 --json 2>/dev/null || echo "[]")

if [ "$history" = "[]" ] || [ -z "$history" ]; then
    log "⚠️ 无消息历史"
    exit 0
fi

# 处理消息
echo "$history" | node -e "
const fs = require('fs');
const messages = JSON.parse(fs.readFileSync(0, 'utf8'));
const lastCheck = parseInt(process.argv[1]) || 0;
const sessionKey = process.argv[2];

// 倒序处理
let newMessages = [];
for (const msg of messages.reverse()) {
    const ts = msg.createdAtMs || 0;
    // 只处理用户消息，且在最后检查时间之后
    if (msg.role === 'user' && ts > lastCheck) {
        const text = msg.content?.[0]?.text || msg.content || '';
        if (text && text.length > 0) {
            newMessages.push({id: msg.id, text, ts});
        }
    }
}

// 输出新消息
for (const m of newMessages) {
    console.log('MSG:' + JSON.stringify(m));
}

// 输出最新时间
const latest = messages.length > 0 ? (messages[messages.length-1].createdAtMs || Date.now()) : Date.now();
console.log('TIME:' + latest);
" "$last_check" "$session_id" | while IFS= read -r line; do
    if [[ "$line" == MSG:* ]]; then
        msg_json="${line#MSG:}"
        text=$(echo "$msg_json" | node -e "console.log(JSON.parse(require('fs').readFileSync(0)).text)")
        
        # 过滤特殊消息
        if [[ "$text" == *"NO_REPLY"* ]] || [[ "$text" == *"HEARTBEAT_OK"* ]]; then
            log "[跳过] 系统消息"
            continue
        fi
        
        log "📤 转发：${text:0:50}..."
        
        # 发送到飞书
        $OPENCLAW_CMD message send --channel feishu --target "$FEISHU_USER" --message "💬 Webchat 消息:\n$text" 2>&1 | tee -a "$LOG_FILE" || true
    elif [[ "$line" == TIME:* ]]; then
        new_time="${line#TIME:}"
        node -e "const fs=require('fs'); const s=JSON.parse(fs.readFileSync('$STATE_FILE')); s.lastCheck=$new_time; fs.writeFileSync('$STATE_FILE',JSON.stringify(s))"
        log "✅ 更新时间：$new_time"
    fi
done

log "=== 同步结束 ==="
