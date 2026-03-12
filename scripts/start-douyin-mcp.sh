#!/bin/bash
# 抖音 MCP 服务启动脚本

VENV_PATH="/tmp/douyin-venv2"
SCRIPT_PATH="/tmp/start_douyin_mcp.py"
LOG_PATH="/tmp/douyin-mcp.log"
PID_FILE="/tmp/douyin-mcp.pid"

# 检查服务是否已在运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ 抖音 MCP 服务已在运行 (PID: $PID)"
        exit 0
    fi
fi

# 启动服务
cd /tmp
nohup "$VENV_PATH/bin/python" "$SCRIPT_PATH" > "$LOG_PATH" 2>&1 &
echo $! > "$PID_FILE"

sleep 2
echo "✅ 抖音 MCP 服务已启动 (PID: $(cat $PID_FILE))"
echo "📍 访问地址：http://localhost:18070/mcp"
