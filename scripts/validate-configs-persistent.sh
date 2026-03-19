#!/bin/bash
# 配置持久化检查 - 确保所有约定都写进了文件
# 使用：./scripts/validate-configs-persistent.sh

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace

echo "🔍 配置持久化检查 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

ISSUES=0

# ==================== 检查 1: HEARTBEAT.md 是否包含所有 cron 任务 ====================
echo ""
echo "📋 检查 1: HEARTBEAT.md 是否包含所有 cron 任务"
echo "----------------------------------------"

# 获取所有 cron 任务
CRON_LIST=$(openclaw cron list 2>/dev/null | grep "cron" | awk '{print $3}' | grep -v "Name")

for CRON_ID in $CRON_LIST; do
  CRON_NAME=$(openclaw cron list 2>/dev/null | grep "$CRON_ID" | awk '{print $3}')
  
  if grep -q "$CRON_ID" HEARTBEAT.md 2>/dev/null; then
    echo "   ✅ ${CRON_NAME} (${CRON_ID}) - 已记录"
  else
    echo "   ❌ ${CRON_NAME} (${CRON_ID}) - 未记录到 HEARTBEAT.md"
    ISSUES=$((ISSUES + 1))
  fi
done

# ==================== 检查 2: 脚本文件是否存在 ====================
echo ""
echo "📋 检查 2: 脚本文件是否存在"
echo "----------------------------------------"

SCRIPTS=(
  "scripts/morning-news.sh"
  "scripts/daily-hot-report-ultimate.sh"
  "scripts/castle-six-daily-questionnaire.sh"
  "scripts/health-daily-review.sh"
  "scripts/growth-daily-review.sh"
  "scripts/merge-daily-audio.sh"
)

for SCRIPT in "${SCRIPTS[@]}"; do
  if [ -f "$SCRIPT" ]; then
    echo "   ✅ ${SCRIPT} - 存在"
  else
    echo "   ❌ ${SCRIPT} - 不存在"
    ISSUES=$((ISSUES + 1))
  fi
done

# ==================== 检查 3: 服务器脚本是否存在 ====================
echo ""
echo "📋 检查 3: 服务器启动脚本是否存在"
echo "----------------------------------------"

SERVER_SCRIPTS=(
  "health-form/server.js"
  "growth-form/server.js"
  "wealth-form/server.js"
  "quiz-form/server.js"
  "scripts/start-health-public.sh"
  "scripts/start-growth-public.sh"
  "scripts/start-wealth-public.sh"
)

for SCRIPT in "${SERVER_SCRIPTS[@]}"; do
  if [ -f "$SCRIPT" ]; then
    echo "   ✅ ${SCRIPT} - 存在"
  else
    echo "   ❌ ${SCRIPT} - 不存在"
    ISSUES=$((ISSUES + 1))
  fi
done

# ==================== 检查 4: cron 表达式是否一致 ====================
echo ""
echo "📋 检查 4: cron 表达式一致性检查"
echo "----------------------------------------"

# 检查晨报 cron
CRON_ACTUAL=$(openclaw cron list 2>/dev/null | grep "每日晨报" | awk '{print $4, $5, $6, $7}')
CRON_EXPECTED="0 7 * * *"

if [[ "$CRON_ACTUAL" == *"0 7 * *"* ]]; then
  echo "   ✅ 每日晨报 cron 正确：${CRON_ACTUAL}"
else
  echo "   ⚠️ 每日晨报 cron 可能不一致：${CRON_ACTUAL}"
  echo "      预期：${CRON_EXPECTED}"
fi

# 检查爆款日报 cron
CRON_ACTUAL=$(openclaw cron list 2>/dev/null | grep "每日爆款日报" | awk '{print $4, $5, $6, $7}')
CRON_EXPECTED="30 7 * * *"

if [[ "$CRON_ACTUAL" == *"30 7 * *"* ]]; then
  echo "   ✅ 每日爆款日报 cron 正确：${CRON_ACTUAL}"
else
  echo "   ⚠️ 每日爆款日报 cron 可能不一致：${CRON_ACTUAL}"
  echo "      预期：${CRON_EXPECTED}"
fi

# ==================== 检查 5: 日志文件是否可写 ====================
echo ""
echo "📋 检查 5: 日志目录是否可写"
echo "----------------------------------------"

LOG_DIRS=(
  "logs"
  "logs/stress-test"
  "daily-output"
  "reports"
)

for DIR in "${LOG_DIRS[@]}"; do
  if [ -d "$DIR" ] && [ -w "$DIR" ]; then
    echo "   ✅ ${DIR} - 可写"
  else
    echo "   ⚠️ ${DIR} - 不存在或不可写"
    mkdir -p "$DIR" 2>/dev/null && echo "      已创建" || ISSUES=$((ISSUES + 1))
  fi
done

# ==================== 检查 6: 飞书插件配置 ====================
echo ""
echo "📋 检查 6: 飞书插件配置"
echo "----------------------------------------"

if grep -q "feishu" config.json 2>/dev/null || grep -q "feishu" ~/.openclaw/config.json 2>/dev/null; then
  echo "   ✅ 飞书插件已配置"
else
  echo "   ⚠️ 飞书插件配置未找到（可能正常，如果是通过扩展配置）"
fi

# ==================== 生成报告 ====================
echo ""
echo "========================================"
echo "📊 配置检查完成 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

if [ $ISSUES -eq 0 ]; then
  echo "🎉 所有配置检查通过！"
  echo ""
  echo "✅ 系统配置完整，可以投入使用"
else
  echo "⚠️ 发现 ${ISSUES} 个问题"
  echo ""
  echo "建议："
  echo "1. 修复上述问题"
  echo "2. 重新运行此脚本验证"
  echo "3. 运行压力测试脚本"
fi

echo ""

# 发送报告到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🔍 配置持久化检查报告

📊 检查结果
━━━━━━━━━━━━━━━━━━
发现问题：${ISSUES} 个

$(if [ $ISSUES -eq 0 ]; then echo "✅ 所有配置检查通过，系统配置完整"; else echo "⚠️ 发现 ${ISSUES} 个问题，建议修复"; fi)

📋 检查项目
━━━━━━━━━━━━━━━━━━
1. HEARTBEAT.md 配置记录
2. 脚本文件完整性
3. 服务器启动脚本
4. cron 表达式一致性
5. 日志目录权限
6. 飞书插件配置

🏰 城堡配置检查 | $(date '+%Y-%m-%d')"

exit $ISSUES
