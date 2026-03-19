#!/bin/bash
# Webchat → 飞书 消息同步脚本 v7（只转发真实用户消息）
# 每分钟轮询 session 历史，转发用户新消息到飞书

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/webchat-to-feishu.log"
STATE_FILE="$WORKSPACE/memory/webchat-mirror-state.json"
SESSION_STORE="/Users/liwang/.openclaw/agents/main/sessions"
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

# 获取最新 session 文件
latest_session=$(ls -t "$SESSION_STORE"/*.jsonl 2>/dev/null | head -1)

if [ -z "$latest_session" ]; then
    log "⚠️ 无 session 文件"
    exit 0
fi

log "Session: $latest_session"

# 获取最后检查时间
last_check=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$STATE_FILE')).lastCheck || 0)" 2>/dev/null || echo "0")

# 读取最新 30 条消息并处理
node -e "
const fs = require('fs');
const file = process.argv[1];
const lastCheck = parseInt(process.argv[2]) || 0;

try {
    const lines = fs.readFileSync(file, 'utf8').trim().split('\n').slice(-30);
    let newMessages = [];
    let latestTime = lastCheck;
    
    for (const line of lines) {
        if (!line.trim()) continue;
        const entry = JSON.parse(line);
        
        // 跳过非消息条目
        if (entry.type !== 'message') continue;
        
        const msg = entry.message || {};
        const role = msg.role || '';
        
        // 时间戳处理
        let ts = 0;
        if (msg.timestamp) {
            ts = new Date(msg.timestamp).getTime();
        } else if (msg.timestampMs) {
            ts = msg.timestampMs;
        } else if (entry.timestamp) {
            ts = new Date(entry.timestamp).getTime();
        }
        
        if (ts > latestTime) latestTime = ts;
        
        // 只处理用户消息（assistant 和 user）
        if (role === 'user' && ts > lastCheck) {
            // 内容提取
            let text = '';
            if (msg.content && Array.isArray(msg.content)) {
                // 跳过 thinking 和 toolCall
                const textContent = msg.content.find(c => c.type === 'text');
                text = textContent?.text || '';
            } else if (typeof msg.content === 'string') {
                text = msg.content;
            }
            
            // 过滤系统消息和工具消息
            if (!text || text.length === 0) continue;
            if (text.includes('NO_REPLY') || text.includes('HEARTBEAT_OK')) continue;
            if (text.includes('A scheduled reminder') || text.includes('Exec completed')) continue;
            
            // 提取真实用户消息（过滤元数据）
            let cleanText = text;
            
            // 移除 System: 开头的系统消息
            if (text.includes('System:') && (text.includes('exec:') || text.includes('reminder'))) {
                continue; // 跳过纯系统消息
            }
            
            // 移除 Sender (untrusted metadata) 部分，保留实际用户消息
            if (text.includes('Sender (untrusted metadata)')) {
                const match = text.match(/\[Fri.*GMT\]\s*(.+)$/m);
                if (match && match[1]) {
                    cleanText = match[1].trim();
                } else {
                    continue; // 无法提取，跳过
                }
            }
            
            // 只保留纯文本消息（不要太长）
            cleanText = cleanText.trim().substring(0, 500);
            if (cleanText.length > 0 && cleanText.length < 500) {
                newMessages.push({ts, text: cleanText});
            }
        }
    }
    
    // 输出新消息
    for (const m of newMessages) {
        console.log('MSG:' + JSON.stringify(m));
    }
    
    console.log('TIME:' + latestTime);
} catch (e) {
    console.log('ERROR:' + e.message);
    console.log('TIME:' + Date.now());
}
" "$latest_session" "$last_check" | while IFS= read -r line; do
    if [[ "$line" == MSG:* ]]; then
        msg_json="${line#MSG:}"
        text=$(echo "$msg_json" | node -e "console.log(JSON.parse(require('fs').readFileSync(0)).text)" 2>/dev/null || echo "")
        
        if [ -z "$text" ]; then
            log "[跳过] 空消息"
            continue
        fi
        
        log "📤 转发：${text:0:50}..."
        
        # 发送到飞书
        $OPENCLAW_CMD message send --channel feishu --target "$FEISHU_USER" --message "💬 Webchat 消息:\n$text" 2>&1 | tee -a "$LOG_FILE" || log "发送失败"
    elif [[ "$line" == TIME:* ]]; then
        new_time="${line#TIME:}"
        node -e "const fs=require('fs'); const s=JSON.parse(fs.readFileSync('$STATE_FILE')); s.lastCheck=$new_time; fs.writeFileSync('$STATE_FILE',JSON.stringify(s))" 2>/dev/null || true
        log "✅ 更新时间：$new_time"
    elif [[ "$line" == ERROR:* ]]; then
        error="${line#ERROR:}"
        log "❌ 解析错误：$error"
    fi
done

log "=== 同步结束 ==="
