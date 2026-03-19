#!/bin/bash
# Strava 数据自动同步脚本
# 每小时同步一次最新运动数据

# Cleanup 机制
cleanup() {
  local exit_code=$?
  log "清理临时资源..."
  rm -f /tmp/strava_*.tmp 2>/dev/null || true
  [ $exit_code -eq 0 ] && log "✅ Strava 同步完成" || log "❌ Strava 同步失败 ($exit_code)"
  exit $exit_code
}
trap cleanup EXIT INT TERM

# 超时设置
TIMEOUT_SECONDS=60

set -e

cd /Users/liwang/.openclaw/workspace
mkdir -p logs

LOG_FILE="logs/strava-sync.log"
TOKEN_FILE="config/strava-tokens.json"
OUTPUT_FILE="data/strava/latest-activities.json"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "=== Strava 数据同步开始 (超时：${TIMEOUT_SECONDS}秒) ==="

# 检查 Token 文件
if [ ! -f "$TOKEN_FILE" ]; then
    log "❌ Token 文件不存在：$TOKEN_FILE"
    exit 1
fi

# 自动刷新 Token
EVAL_OUTPUT=$(./scripts/auto-refresh-strava-token.sh 2>&1)
if echo "$EVAL_OUTPUT" | grep -q "EXPORT_TOKENS=1"; then
    eval "$(echo "$EVAL_OUTPUT" | grep "^STRAVA_")"
    log "✅ Token 已就绪"
else
    log "❌ Token 刷新失败：$EVAL_OUTPUT"
    exit 1
fi

# 获取最新 30 条运动记录
log "📊 获取 Strava 运动数据..."
RESPONSE=$(curl -s -G "https://www.strava.com/api/v3/athlete/activities" \
    -H "Authorization: Bearer $STRAVA_TOKEN" \
    -d "per_page=30")

# 检查响应是否有效
if echo "$RESPONSE" | grep -q "Authorization Error"; then
    log "❌ 授权失败，Token 可能已失效"
    log "错误：$RESPONSE"
    exit 1
fi

# 保存数据
echo "$RESPONSE" > "$OUTPUT_FILE"
ACTIVITY_COUNT=$(echo "$RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d.length)")

log "✅ 成功获取 $ACTIVITY_COUNT 条运动记录"
log "📁 数据已保存：$OUTPUT_FILE"

# 显示最新活动
node -e "
const fs = require('fs');
const activities = JSON.parse(fs.readFileSync('$OUTPUT_FILE', 'utf8'));
if (activities.length > 0) {
  const latest = activities[0];
  const date = latest.start_date_local.split('T')[0];
  const time = latest.start_date_local.split('T')[1].substring(0,5);
  const distance = (latest.distance / 1000).toFixed(2);
  const duration = Math.round(latest.moving_time / 60);
  console.log('🏃 最新活动:', latest.name);
  console.log('   日期:', date, time);
  console.log('   类型:', latest.sport_type || latest.type);
  console.log('   距离:', distance + 'km');
  console.log('   时长:', duration + '分钟');
}
" 2>/dev/null || true

log "=== Strava 数据同步完成 ==="
