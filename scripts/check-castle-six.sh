#!/bin/bash
# Castle Six 自检脚本
# 检查所有城堡系统是否正常运行

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/castle-six-check.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_server() {
    local name=$1
    local port=$2
    
    if curl -s "http://localhost:$port" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $name 服务器运行正常 (端口 $port)"
        return 0
    else
        echo -e "${RED}❌${NC} $name 服务器未运行 (端口 $port)"
        return 1
    fi
}

check_cron() {
    local name=$1
    local pattern=$2
    
    if openclaw cron list 2>/dev/null | grep -q "$pattern"; then
        echo -e "${GREEN}✅${NC} $name cron 任务已配置"
        return 0
    else
        echo -e "${RED}❌${NC} $name cron 任务未找到"
        return 1
    fi
}

check_file() {
    local name=$1
    local path=$2
    
    if [ -f "$path" ]; then
        echo -e "${GREEN}✅${NC} $name 文件存在"
        return 0
    else
        echo -e "${RED}❌${NC} $name 文件不存在"
        return 1
    fi
}

log "=== Castle Six 自检开始 ==="
echo ""
echo "🏰 Castle Six 系统健康检查"
echo "=========================="
echo ""

# 服务器检查
echo "📡 服务器状态："
echo "--------------"
check_server "健康堡" "8897" || true
check_server "成长堡" "8896" || true
# check_server "事业堡" "8898" || true
# check_server "关系堡" "8899" || true
# check_server "财富堡" "8900" || true
# check_server "生活堡" "8901" || true
echo ""

# Cron 任务检查
echo "⏰ Cron 任务："
echo "-------------"
check_cron "Castle Six 问卷发送" "Castle Six 每日问卷发送" || true
check_cron "健康堡复盘" "健康堡每日复盘" || true
check_cron "成长堡计划" "成长堡每日计划" || true
check_cron "成长堡复盘" "成长堡每日复盘" || true
check_cron "总复盘堡简报" "总复盘堡每日简报" || true
echo ""

# 文件检查
echo "📁 核心文件："
echo "------------"
check_file "健康堡表单" "$WORKSPACE/health-form/index.html" || true
check_file "健康堡服务器" "$WORKSPACE/health-form/server.js" || true
check_file "成长堡表单" "$WORKSPACE/growth-form/index.html" || true
check_file "成长堡服务器" "$WORKSPACE/growth-form/server.js" || true
check_file "统一发送脚本" "$WORKSPACE/scripts/castle-six-daily-questionnaire.sh" || true
check_file "HEARTBEAT 配置" "$WORKSPACE/HEARTBEAT.md" || true
echo ""

# 数据目录检查
echo "📊 数据目录："
echo "------------"
check_file "健康数据目录" "$WORKSPACE/daily-output/health/daily-stats" || true
check_file "成长数据目录" "$WORKSPACE/daily-output/growth/daily-stats" || true
echo ""

# 日志检查
echo "📝 最近日志："
echo "------------"
if [ -f "$WORKSPACE/logs/castle-six-sender.log" ]; then
    echo "发送日志（最后 3 行）："
    tail -3 "$WORKSPACE/logs/castle-six-sender.log"
else
    echo "⚠️  发送日志不存在"
fi
echo ""

# 总结
echo "=========================="
echo "✅ Castle Six 自检完成"
echo ""

log "=== Castle Six 自检完成 ==="
