#!/bin/bash
# 飞书消息轮询同步脚本
# 每分钟检查飞书新消息，转发到 Webchat

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/feishu-poll.log"
STATE_FILE="$WORKSPACE/memory/feishu-poll-state.json"
CONFIG_FILE="$WORKSPACE/config/feishu-poll-config.json"
OPENCLAW_CMD="/opt/homebrew/bin/openclaw"
NODE_CMD="/opt/homebrew/bin/node"
FETCH_SCRIPT="$WORKSPACE/scripts/feishu-fetch-messages.js"

# 飞书应用配置
APP_ID="cli_a92ebaa37eb89cb0"
APP_SECRET="NFgwZT7bEZlvo5jKmI814ggDcykrL5A7"
TARGET_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 初始化配置文件
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"chat_id": ""}' > "$CONFIG_FILE"
    fi
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"processed_messages": []}' > "$STATE_FILE"
    fi
}

# 获取飞书 access_token
get_access_token() {
    $NODE_CMD -e "
const https = require('https');
const data = JSON.stringify({ app_id: '$APP_ID', app_secret: '$APP_SECRET' });
const req = https.request({
    hostname: 'open.feishu.cn', port: 443,
    path: '/open-apis/auth/v3/tenant_access_token/internal',
    method: 'POST', headers: { 'Content-Type': 'application/json; charset=utf-8' }
}, (res) => {
    let body = '';
    res.on('data', (chunk) => { body += chunk; });
    res.on('end', () => {
        const result = JSON.parse(body);
        console.log(result.tenant_access_token || '');
    });
});
req.write(data);
req.end();
"
}

# 获取或创建 chat_id
get_chat_id() {
    local access_token="$1"
    
    # 先尝试从配置文件读取
    local cached_chat_id
    cached_chat_id=$($NODE_CMD -e "console.log(JSON.parse(require('fs').readFileSync('$CONFIG_FILE')).chat_id || '')")
    
    if [ -n "$cached_chat_id" ]; then
        echo "$cached_chat_id"
        return
    fi
    
    # 没有缓存，发送一条消息获取 chat_id
    local result
    result=$($NODE_CMD -e "
const https = require('https');
const req = https.request({
    hostname: 'open.feishu.cn', port: 443,
    path: '/open-apis/im/v1/messages?receive_id_type=open_id',
    method: 'POST',
    headers: { 
        'Authorization': 'Bearer $access_token',
        'Content-Type': 'application/json; charset=utf-8'
    }
}, (res) => {
    let body = '';
    res.on('data', (chunk) => { body += chunk; });
    res.on('end', () => {
        const result = JSON.parse(body);
        if (result.code === 0 && result.data && result.data.chat_id) {
            console.log(result.data.chat_id);
        } else {
            console.log('');
        }
    });
});
req.write(JSON.stringify({
    receive_id: '$TARGET_USER',
    msg_type: 'text',
    content: JSON.stringify({ text: '消息同步初始化' })
}));
req.end();
")
    
    if [ -n "$result" ]; then
        $NODE_CMD -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('$CONFIG_FILE'));
config.chat_id = '$result';
fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config));
"
        echo "$result"
    fi
}

# 转发消息到 webchat (已禁用 - 2026-03-08)
forward_to_webchat() {
    local sender="$1"
    local text="$2"
    
    # 功能已禁用 - 不再转发到 webchat/iMessage
    log "[已禁用] 跳过转发消息到 webchat: $sender - ${text:0:50}..."
    return 0
}

# 主函数
main() {
    log "=== 飞书消息轮询开始 ==="
    
    init_config
    
    # 获取 access_token
    log "获取 access_token..."
    local access_token
    access_token=$(get_access_token)
    
    if [ -z "$access_token" ]; then
        log "获取 access_token 失败"
        log "=== 飞书消息轮询结束 ==="
        return 1
    fi
    log "access_token 获取成功"
    
    # 获取 chat_id
    log "获取 chat_id..."
    local chat_id
    chat_id=$(get_chat_id "$access_token")
    
    if [ -z "$chat_id" ]; then
        log "获取 chat_id 失败"
        log "=== 飞书消息轮询结束 ==="
        return 1
    fi
    log "chat_id: $chat_id"
    
    # 获取新消息
    log "获取新消息..."
    local output
    output=$($NODE_CMD "$FETCH_SCRIPT" "$chat_id" "$access_token" "$STATE_FILE" 2>&1)
    
    local message_count=0
    while IFS= read -r line; do
        if [[ "$line" == NEW_MESSAGE:* ]]; then
            local msg_json="${line#NEW_MESSAGE:}"
            local sender text
            sender=$($NODE_CMD -e "console.log(JSON.parse('$msg_json').sender)")
            text=$($NODE_CMD -e "console.log(JSON.parse('$msg_json').text)")
            
            log "收到新消息：$sender - ${text:0:50}..."
            
            # 转发到 webchat
            forward_to_webchat "$sender" "$text"
            
            message_count=$((message_count + 1))
        elif [[ "$line" == DONE:* ]]; then
            local count="${line#DONE:}"
            log "本次处理了 $count 条新消息"
        fi
    done <<< "$output"
    
    log "=== 飞书消息轮询结束 ==="
}

main "$@"
