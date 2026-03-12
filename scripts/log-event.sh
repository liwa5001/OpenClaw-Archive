#!/bin/bash
# 统一日志记录脚本
# 用途：记录技能安装、软件安装、配置变更等信息
# 同时写入：1) 日志文件 (QMD 索引)  2) agent-memory (结构化记忆)

set -e

LOG_DIR="/Users/liwang/.openclaw/workspace/logs"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 用法：log_event "类型" "内容" [标签...]
# 示例：log_event "skill" "Agent Reach" "安装" "搜索"
log_event() {
    local TYPE="$1"
    local CONTENT="$2"
    shift 2
    local TAGS="$@"
    
    # 1. 写入日志文件 (QMD 会索引)
    local LOG_FILE="$LOG_DIR/${TYPE}-${DATE}.log"
    echo "[$TIMESTAMP] $CONTENT" >> "$LOG_FILE"
    echo "✅ 已记录到 $LOG_FILE"
    
    # 2. 写入 agent-memory (结构化记忆)
    cd /Users/liwang/.openclaw/workspace/skills/agent-memory
    uv run python -c "
from src.memory import AgentMemory
mem = AgentMemory()
mem.remember('$CONTENT', tags=['$TYPE', '$(echo $TAGS | tr ' ' ',')'])
print('✅ 已记忆到 agent-memory')
" 2>/dev/null || echo "⚠️ agent-memory 记录失败"
}

# 快捷命令
case "$1" in
    skill)
        log_event "skill" "$2" "技能" "${@:3}"
        ;;
    app)
        log_event "app" "$2" "软件" "${@:3}"
        ;;
    config)
        log_event "config" "$2" "配置" "${@:3}"
        ;;
    error)
        log_event "error" "$2" "错误" "${@:3}"
        ;;
    *)
        echo "用法：$0 {skill|app|config|error} '内容' [标签...]"
        echo "示例：$0 skill 'Agent Reach' '安装' '搜索'"
        exit 1
        ;;
esac
