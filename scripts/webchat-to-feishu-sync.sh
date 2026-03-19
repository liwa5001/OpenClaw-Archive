#!/bin/bash
# Webchat → 飞书 消息同步脚本
# 每分钟轮询 session 历史，转发新消息到飞书

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/webchat-to-feishu.log"
STATE_FILE="$WORKSPACE/memory/webchat-mirror-state.json"
OPENCLAW_CMD="/opt/homebrew/bin/openclaw"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 初始化状态文件
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"lastMessageId": "", "lastCheckTime": 0, "processedCount": 0}' > "$STATE_FILE"
        log "状态文件已初始化"
    fi
}

# 获取最后一条消息 ID
get_last_message_id() {
    node -e "console.log(JSON.parse(require('fs').readFileSync('$STATE_FILE')).lastMessageId || '')"
}

# 更新状态
update_state() {
    local last_id="$1"
    local count="$2"
    node -e "
const fs = require('fs');
const state = JSON.parse(fs.readFileSync('$STATE_FILE'));
state.lastMessageId = '$last_id';
state.lastCheckTime = Date.now();
state.processedCount = (state.processedCount || 0) + $count;
fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
"
}

# 获取当前 session 历史
get_session_history() {
    $OPENCLAW_CMD sessions list --limit 1 --json 2>/dev/null | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
if (data && data.length > 0) {
    console.log(data[0].id);
}
"
}

# 转发消息到飞书
forward_to_feishu() {
    local text="$1"
    local sender="$2"
    
    # 过滤系统消息和工具调用
    if [[ "$text" == *"NO_REPLY"* ]] || [[ "$text" == *"HEARTBEAT_OK"* ]]; then
        log "[跳过] 系统消息：${text:0:30}..."
        return
    fi
    
    # 过滤机器人自己的回复（避免循环）
    if [[ "$text" == *"🏰"* ]] && [[ "$text" == *"城堡"* ]]; then
        log "[跳过] 机器人自己的消息"
        return
    fi
    
    log "📤 转发到飞书：${text:0:50}..."
    
    # 发送到飞书
    $OPENCLAW_CMD message send --channel feishu --target "$FEISHU_USER" --message "💬 Webchat 消息:\n$text" 2>&1 | tee -a "$LOG_FILE"
}

# 主函数
main() {
    log "=== Webchat → 飞书 同步开始 ==="
    
    init_state
    
    # 获取当前 session
    local session_id
    session_id=$(get_session_history)
    
    if [ -z "$session_id" ]; then
        log "⚠️ 未找到活跃的 webchat session"
        log "=== Webchat → 飞书 同步结束 ==="
        return 0
    fi
    
    log "当前 session: $session_id"
    
    # 获取最后一条消息 ID
    local last_id
    last_id=$(get_last_message_id)
    
    # 获取最近的消息（最多 10 条）
    local messages
    messages=$($OPENCLAW_CMD sessions history --sessionKey "$session_id" --limit 10 --json 2>/dev/null || echo "[]")
    
    if [ "$messages" = "[]" ] || [ -z "$messages" ]; then
        log "⚠️ 没有新消息"
        log "=== Webchat → 飞书 同步结束 ==="
        return 0
    fi
    
    # 解析并处理新消息
    local new_count=0
    local latest_id=""
    
    echo "$messages" | node -e "
const messages = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const lastId = process.argv[1];

let foundNew = false;
let latestId = '';

// 倒序处理（最新的在前）
for (const msg of messages.reverse()) {
    if (!msg.id) continue;
    
    // 如果是第一条，记录为最新 ID
    if (!latestId) latestId = msg.id;
    
    // 跳过已处理的消息
    if (msg.id === lastId) break;
    if (foundNew) {
        // 输出新消息
        const sender = msg.role === 'user' ? 'user' : 'assistant';
        const text = msg.content?.[0]?.text || msg.content || '';
        if (text) {
            console.log('NEW:' + JSON.stringify({id: msg.id, sender, text}));
        }
    } else {
        // 检查是否找到最后一条已处理的消息
        if (msg.id === lastId || lastId === '') {
            foundNew = true;
        }
    }
}

// 输出最新 ID
console.log('LATEST:' + latestId);
" "$last_id" | while IFS= read -r line; do
        if [[ "$line" == NEW:* ]]; then
            local msg_json="${line#NEW:}"
            local sender text
            sender=$(echo "$msg_json" | node -e "console.log(JSON.parse(require('fs').readFileSync(0, 'utf8')).sender)")
            text=$(echo "$msg_json" | node -e "console.log(JSON.parse(require('fs').readFileSync(0, 'utf8')).text)")
            
            log "📝 新消息 ($sender): ${text:0:50}..."
            
            # 只转发用户消息
            if [ "$sender" = "user" ]; then
                forward_to_feishu "$text" "$sender"
                new_count=$((new_count + 1))
            fi
        elif [[ "$line" == LATEST:* ]]; then
            latest_id="${line#LATEST:}"
        fi
    done
    
    # 更新状态
    if [ -n "$latest_id" ]; then
        update_state "$latest_id" "$new_count"
        log "✅ 已处理 $new_count 条新消息，最新 ID: $latest_id"
    fi
    
    log "=== Webchat → 飞书 同步结束 ==="
}

main "$@"
