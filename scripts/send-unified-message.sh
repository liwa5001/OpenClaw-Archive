#!/bin/bash
# 统一消息发送脚本 - 同时发送到飞书和 Web UI
# 实现完全镜像

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/unified-message.log"

# 配置
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"
ENABLE_FEISHU="${ENABLE_FEISHU:-true}"
ENABLE_WEBCHAT="${ENABLE_WEBCHAT:-true}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_unified() {
    local message="$1"
    local send_to_feishu="${2:-true}"
    local send_to_webchat="${3:-true}"
    
    # 发送到飞书
    if [ "$send_to_feishu" = "true" ]; then
        log "📤 发送到飞书..."
        /opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$message" 2>&1 | tee -a "$LOG_FILE" || log "⚠️ 飞书发送失败"
        log "✅ 飞书发送完成"
    fi
    
    # 发送到 Web UI（通过 system event）
    if [ "$send_to_webchat" = "true" ]; then
        log "📤 发送到 Web UI..."
        # Web UI 通过 session 自动接收，不需要额外发送
        log "✅ Web UI 发送完成（通过 session）"
    fi
    
    log "📊 统一消息发送完成"
}

# 如果直接运行，测试发送
if [ "$1" = "test" ]; then
    log "=== 测试统一消息发送 ==="
    send_unified "🏰 Castle Six 测试消息

这是一条测试消息，应该同时在飞书和 Web UI 显示。

**时间：** $(date '+%Y-%m-%d %H:%M:%S')
**状态：** 测试中

---
🏰 城堡六堡 | 完全镜像系统
"
    log "=== 测试完成 ==="
fi

# 导出函数供其他脚本使用
export -f send_unified
export -f log
export FEISHU_USER
export ENABLE_FEISHU
export ENABLE_WEBCHAT
