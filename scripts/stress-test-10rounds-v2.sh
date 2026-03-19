#!/bin/bash
# 连续 10 轮压力测试 v2 - 修复会话复用问题
# 使用：./scripts/stress-test-10rounds-v2.sh

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace
mkdir -p logs/stress-test

echo "🚨 开始连续 10 轮压力测试 v2（修复版） - $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo "修复内容：每个任务使用独立会话，避免复用冲突"
echo "每轮间隔 30 秒，预计耗时 10-15 分钟"
echo ""

# 总统计
GRAND_TOTAL=0
GRAND_SUCCESS=0
GRAND_FAILED=0

# 10 轮测试
for ROUND in {1..10}; do
  echo ""
  echo "========================================"
  echo "🔁 第 ${ROUND}/10 轮 - $(date '+%H:%M:%S')"
  echo "========================================"
  
  ROUND_TOTAL=0
  ROUND_SUCCESS=0
  ROUND_FAILED=0
  
  # 为每个任务生成唯一会话 ID
  TIMESTAMP=$(date +%s%N)
  
  # 测试 1: 每日晨报（使用独立会话）
  ROUND_TOTAL=$((ROUND_TOTAL + 1))
  GRAND_TOTAL=$((GRAND_TOTAL + 1))
  
  echo -n "   测试：每日晨报 ... "
  if openclaw sessions spawn --runtime subagent --label "stress-test-morning-${ROUND}" --task "生成今日晨报并发送到飞书" --mode run --timeout-seconds 60 > /dev/null 2>&1; then
    echo "✅"
    ROUND_SUCCESS=$((ROUND_SUCCESS + 1))
    GRAND_SUCCESS=$((GRAND_SUCCESS + 1))
  else
    echo "❌"
    ROUND_FAILED=$((ROUND_FAILED + 1))
    GRAND_FAILED=$((GRAND_FAILED + 1))
    echo "   [$(date '+%H:%M:%S')] 第 ${ROUND} 轮：每日晨报失败" >> logs/stress-test/round-${ROUND}-failures.log
  fi
  
  # 测试 2: 每日爆款日报（使用独立会话）
  ROUND_TOTAL=$((ROUND_TOTAL + 1))
  GRAND_TOTAL=$((GRAND_TOTAL + 1))
  
  echo -n "   测试：每日爆款日报 ... "
  if openclaw sessions spawn --runtime subagent --label "stress-test-hot-${ROUND}" --task "生成今日爆款日报并发送到飞书" --mode run --timeout-seconds 90 > /dev/null 2>&1; then
    echo "✅"
    ROUND_SUCCESS=$((ROUND_SUCCESS + 1))
    GRAND_SUCCESS=$((GRAND_SUCCESS + 1))
  else
    echo "❌"
    ROUND_FAILED=$((ROUND_FAILED + 1))
    GRAND_FAILED=$((GRAND_FAILED + 1))
    echo "   [$(date '+%H:%M:%S')] 第 ${ROUND} 轮：每日爆款日报失败" >> logs/stress-test/round-${ROUND}-failures.log
  fi
  
  # 测试 3: 健康堡每日问卷（直接运行脚本）
  ROUND_TOTAL=$((ROUND_TOTAL + 1))
  GRAND_TOTAL=$((GRAND_TOTAL + 1))
  
  echo -n "   测试：健康堡每日问卷 ... "
  if ./scripts/castle-six-daily-questionnaire.sh > /dev/null 2>&1; then
    echo "✅"
    ROUND_SUCCESS=$((ROUND_SUCCESS + 1))
    GRAND_SUCCESS=$((GRAND_SUCCESS + 1))
  else
    echo "❌"
    ROUND_FAILED=$((ROUND_FAILED + 1))
    GRAND_FAILED=$((GRAND_FAILED + 1))
    echo "   [$(date '+%H:%M:%S')] 第 ${ROUND} 轮：健康堡每日问卷失败" >> logs/stress-test/round-${ROUND}-failures.log
  fi
  
  # 轮次统计
  echo ""
  echo "   第 ${ROUND} 轮结果：${ROUND_SUCCESS}/${ROUND_TOTAL} 成功"
  
  # 间隔 30 秒（模拟时间流逝，让 Gateway 恢复）
  if [ $ROUND -lt 10 ]; then
    echo "   ⏳ 等待 30 秒后继续下一轮..."
    sleep 30
  fi
done

# ==================== 最终统计 ====================
echo ""
echo "========================================"
echo "📊 10 轮压力测试完成 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo "总测试数：${GRAND_TOTAL}"
echo "成功：${GRAND_SUCCESS}"
echo "失败：${GRAND_FAILED}"
echo "成功率：$((GRAND_SUCCESS * 100 / GRAND_TOTAL))%"
echo ""

# 生成报告
REPORT_FILE="logs/stress-test/10rounds-v2-summary-$(date +%Y%m%d_%H%M%S).md"

cat > "$REPORT_FILE" << EOF
# 🚨 10 轮连续压力测试报告 v2（修复版）

**测试时间：** $(date '+%Y-%m-%d %H:%M:%S')  
**测试轮数：** 10 轮  
**每轮间隔：** 30 秒  
**修复内容：** 每个任务使用独立会话，避免复用冲突

## 📊 测试结果

| 指标 | 数值 |
|------|------|
| 总测试数 | ${GRAND_TOTAL} |
| 成功 | ${GRAND_SUCCESS} |
| 失败 | ${GRAND_FAILED} |
| 成功率 | $((GRAND_SUCCESS * 100 / GRAND_TOTAL))% |

## 📈 每轮结果

| 轮次 | 成功 | 失败 | 成功率 |
|------|------|------|--------|
EOF

# 分析每轮结果
for ROUND in {1..10}; do
  if [ -f "logs/stress-test/round-${ROUND}-failures.log" ]; then
    FAILURES=$(grep -c "第 ${ROUND} 轮" "logs/stress-test/round-${ROUND}-failures.log" 2>/dev/null || echo "0")
  else
    FAILURES=0
  fi
  SUCCESSES=$((3 - FAILURES))
  RATE=$((SUCCESSES * 100 / 3))
  echo "| 第 ${ROUND} 轮 | ${SUCCESSES} | ${FAILURES} | ${RATE}% |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

## 🔍 发现的问题

EOF

if [ $GRAND_FAILED -gt 0 ]; then
  echo "共发现 ${GRAND_FAILED} 次失败，详情见各轮日志文件。" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "### 失败日志" >> "$REPORT_FILE"
  for ROUND in {1..10}; do
    if [ -f "logs/stress-test/round-${ROUND}-failures.log" ]; then
      echo "" >> "$REPORT_FILE"
      echo "#### 第 ${ROUND} 轮" >> "$REPORT_FILE"
      cat "logs/stress-test/round-${ROUND}-failures.log" >> "$REPORT_FILE"
    fi
  done
else
  echo "🎉 所有测试通过，无失败！" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

## 📝 建议

EOF

if [ $GRAND_FAILED -eq 0 ]; then
  echo "✅ 所有功能稳定，可以投入使用。" >> "$REPORT_FILE"
elif [ $GRAND_FAILED -le 3 ]; then
  echo "⚠️ 有少量失败（${GRAND_FAILED} 次），建议：" >> "$REPORT_FILE"
  echo "1. 检查失败的任务日志" >> "$REPORT_FILE"
  echo "2. 修复后重新运行压力测试" >> "$REPORT_FILE"
else
  echo "❌ 失败次数较多（${GRAND_FAILED} 次），系统不稳定，建议：" >> "$REPORT_FILE"
  echo "1. 暂停使用，优先修复问题" >> "$REPORT_FILE"
  echo "2. 逐个测试失败的任务" >> "$REPORT_FILE"
  echo "3. 修复后重新运行完整压力测试" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---
🏰 城堡压力测试 | $(date '+%Y-%m-%d')
EOF

echo "📄 详细报告已生成：$REPORT_FILE"
echo ""

# 发送报告到飞书
echo "📤 发送测试报告到飞书..."

/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🚨 10 轮压力测试 v2（修复版）

📊 测试结果
━━━━━━━━━━━━━━━━━━
总测试数：${GRAND_TOTAL}
成功：${GRAND_SUCCESS}
失败：${GRAND_FAILED}
成功率：$((GRAND_SUCCESS * 100 / GRAND_TOTAL))%

🔧 修复内容
━━━━━━━━━━━━━━━━━━
每个任务使用独立会话
避免会话复用冲突

📈 稳定性评估
━━━━━━━━━━━━━━━━━━
$(if [ $GRAND_FAILED -eq 0 ]; then echo "✅ 所有功能稳定，可以投入使用"; elif [ $GRAND_FAILED -le 3 ]; then echo "⚠️ 有少量失败，建议修复后重试"; else echo "❌ 失败次数较多，系统不稳定"; fi)

📄 详细报告：
${REPORT_FILE}

🏰 城堡压力测试 | 连夜跑"

echo ""
echo "✅ 10 轮压力测试 v2 全部完成！"

# 退出码
if [ $GRAND_FAILED -gt 0 ]; then
  exit 1
fi
exit 0
