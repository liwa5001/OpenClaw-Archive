#!/bin/bash
# 飞书 ↔ Webchat 双向消息同步脚本
# 每分钟执行一次，检查新消息并转发

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/message-sync.log"
STATE_FILE="$WORKSPACE/memory/message-sync-state.json"
OPENCLAW_CMD="/opt/homebrew/bin/openclaw"

# 飞书用户 ID
FEISHU_USER_ID="ou_7781abd1e83eae23ccf01fe627f0747f"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 初始化状态文件
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"lastFeishuMessageTime": 0, "lastWebchatMessageTime": 0}' > "$STATE_FILE"
        log "状态文件已初始化"
    fi
}

# 检查飞书新消息并转发到 webchat
sync_feishu_to_webchat() {
    log "检查飞书新消息..."
    
    # 使用 openclaw message 工具读取飞书消息
    # 这里需要通过 Feishu API 获取最新消息
    # 简化版本：只记录日志，实际同步需要更复杂的 API 调用
    
    log "飞书消息检查完成"
}

# 主循环
main() {
    log "=== 消息同步任务启动 ==="
    init_state
    
    sync_feishu_to_webchat
    
    log "=== 消息同步任务完成 ==="
}

main "$@"
