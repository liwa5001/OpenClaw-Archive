#!/bin/bash
# 脚本模板 - 包含超时和 cleanup 机制
# 复制此模板到其他脚本

set -e

# ==================== 配置 ====================
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${WORKSPACE_DIR}/logs"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

# 超时设置（秒）
DEFAULT_TIMEOUT=300
CURL_TIMEOUT=30
NODE_TIMEOUT=60

# ==================== Cleanup 函数 ====================
cleanup() {
  local exit_code=$?
  
  log "清理临时资源..."
  
  # 清理临时文件
  rm -f /tmp/${SCRIPT_NAME%.sh}_*.tmp 2>/dev/null || true
  
  # 停止后台进程
  if [ -n "$BACKGROUND_PID" ]; then
    kill $BACKGROUND_PID 2>/dev/null || true
  fi
  
  # 记录退出状态
  if [ $exit_code -eq 0 ]; then
    log "✅ 脚本执行成功"
  else
    log "❌ 脚本执行失败 (退出码：$exit_code)"
  fi
  
  exit $exit_code
}

# 注册 cleanup 函数
trap cleanup EXIT INT TERM

# ==================== 日志函数 ====================
log() {
  local level="${2:-INFO}"
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# ==================== 初始化 ====================
init() {
  mkdir -p "$LOG_DIR"
  log "========================================"
  log "脚本启动：${SCRIPT_NAME}"
  log "工作目录：${WORKSPACE_DIR}"
  log "日志文件：${LOG_FILE}"
  log "========================================"
}

# ==================== 主逻辑 ====================
main() {
  init
  
  log "开始执行主逻辑..."
  
  # 示例：带超时的 curl 请求
  log "抓取数据（超时：${CURL_TIMEOUT}秒）..."
  if ! timeout $CURL_TIMEOUT curl -s "https://example.com" > /tmp/example.tmp 2>/dev/null; then
    log "请求超时或失败" "ERROR"
    return 1
  fi
  
  # 示例：带超时的 node 命令
  log "执行 Node 脚本（超时：${NODE_TIMEOUT}秒）..."
  if ! timeout $NODE_TIMEOUT node script.js > /tmp/node.tmp 2>/dev/null; then
    log "Node 脚本执行超时或失败" "ERROR"
    return 1
  fi
  
  log "主逻辑执行完成"
}

# 执行
main "$@"
