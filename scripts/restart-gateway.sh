#!/bin/bash
# OpenClaw Gateway 每日自动重启脚本
# 执行时间：每天凌晨 3:00

LOG_FILE="/Users/liwang/.openclaw/workspace/logs/gateway-restart.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] 开始重启 OpenClaw Gateway..." >> "$LOG_FILE"

# 重启 Gateway
/opt/homebrew/bin/openclaw gateway restart >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "[$TIMESTAMP] ✅ Gateway 重启成功" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] ❌ Gateway 重启失败" >> "$LOG_FILE"
fi

echo "[$TIMESTAMP] ---" >> "$LOG_FILE"
