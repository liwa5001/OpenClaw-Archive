#!/bin/bash
# 全功能压力测试脚本 - 连夜跑 10 轮
# 使用：./scripts/stress-test-all.sh

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace
mkdir -p logs/stress-test

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/stress-test/stress-test-${TIMESTAMP}.log"
SUMMARY_FILE="logs/stress-test/stress-test-${TIMESTAMP}-summary.md"

echo "🚨 开始全功能压力测试 - $(date '+%Y-%m-%d %H:%M:%S')" | tee "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 计数器
TOTAL=0
SUCCESS=0
FAILED=0

# 测试函数
test_cron() {
  local name="$1"
  local cron_id="$2"
  TOTAL=$((TOTAL + 1))
  
  echo "" | tee -a "$LOG_FILE"
  echo "📋 测试 #${TOTAL}: ${name}" | tee -a "$LOG_FILE"
  echo "   Cron ID: ${cron_id}" | tee -a "$LOG_FILE"
  echo "   时间：$(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
  
  # 运行 cron 任务
  if openclaw cron run "$cron_id" >> "$LOG_FILE" 2>&1; then
    echo "   ✅ 成功" | tee -a "$LOG_FILE"
    SUCCESS=$((SUCCESS + 1))
    return 0
  else
    echo "   ❌ 失败" | tee -a "$LOG_FILE"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

# ==================== 第 1 轮：核心功能测试 ====================
echo "" | tee -a "$LOG_FILE"
echo "🔥 第 1 轮：核心功能测试（立即执行）" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 1. 每日晨报
test_cron "每日晨报" "2e4a8df1-0ff3-4870-bdce-0f6cac54a047"

# 2. 每日爆款日报
test_cron "每日爆款日报" "312409fd-ecaf-46d6-a463-846ca2c75aad"

# 3. 健康堡每日问卷
test_cron "健康堡每日问卷" "18f367a4-e6fb-48ca-9525-2e4000d3fa8b"

# 4. 健康堡每日复盘
test_cron "健康堡每日复盘" "42b34ea5-8c2f-4b9b-94a1-1fd4f4101ea3"

# 5. 成长堡每日复盘
test_cron "成长堡每日复盘" "5042e91c-08d1-4177-ae20-06d812443ea6"

# 6. 总复盘堡每日简报
test_cron "总复盘堡每日简报" "5f2ec99b-dabb-4f6a-93fd-624befb636b3"

# ==================== 第 2 轮：重复测试 ====================
echo "" | tee -a "$LOG_FILE"
echo "🔁 第 2 轮：重复测试（检查状态残留）" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

test_cron "每日晨报 (重复)" "2e4a8df1-0ff3-4870-bdce-0f6cac54a047"
test_cron "每日爆款日报 (重复)" "312409fd-ecaf-46d6-a463-846ca2c75aad"
test_cron "健康堡每日问卷 (重复)" "18f367a4-e6fb-48ca-9525-2e4000d3fa8b"

# ==================== 第 3 轮：服务器状态测试 ====================
echo "" | tee -a "$LOG_FILE"
echo "🖥️ 第 3 轮：服务器状态测试" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 检查健康堡服务器
echo "检查健康堡服务器 (8897)..." | tee -a "$LOG_FILE"
if curl -s http://localhost:8897/status >> "$LOG_FILE" 2>&1; then
  echo "   ✅ 健康堡服务器正常" | tee -a "$LOG_FILE"
else
  echo "   ⚠️ 健康堡服务器未运行（正常，按需启动）" | tee -a "$LOG_FILE"
fi

# 检查成长堡服务器
echo "检查成长堡服务器 (8896)..." | tee -a "$LOG_FILE"
if curl -s http://localhost:8896/status >> "$LOG_FILE" 2>&1; then
  echo "   ✅ 成长堡服务器正常" | tee -a "$LOG_FILE"
else
  echo "   ⚠️ 成长堡服务器未运行（正常，按需启动）" | tee -a "$LOG_FILE"
fi

# ==================== 生成测试报告 ====================
echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "📊 压力测试完成 - $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "总测试数：${TOTAL}" | tee -a "$LOG_FILE"
echo "成功：${SUCCESS}" | tee -a "$LOG_FILE"
echo "失败：${FAILED}" | tee -a "$LOG_FILE"
echo "成功率：$((SUCCESS * 100 / TOTAL))%" | tee -a "$LOG_FILE"

# 生成 Markdown 报告
cat > "$SUMMARY_FILE" << EOF
# 🚨 压力测试报告

**测试时间：** $(date '+%Y-%m-%d %H:%M:%S')  
**日志文件：** \`$LOG_FILE\`

## 📊 测试结果

| 指标 | 数值 |
|------|------|
| 总测试数 | ${TOTAL} |
| 成功 | ${SUCCESS} |
| 失败 | ${FAILED} |
| 成功率 | $((SUCCESS * 100 / TOTAL))% |

## ✅ 测试通过的功能

$(grep "✅ 成功" "$LOG_FILE" | sed 's/.*测试 #\([0-9]*\): \(.*\)/- \2 (测试 #\1)/')

## ❌ 测试失败的功能

$(grep "❌ 失败" "$LOG_FILE" | sed 's/.*测试 #\([0-9]*\): \(.*\)/- \2 (测试 #\1)/' || echo "无")

## 🔍 发现的问题

$(grep -E "error|Error|失败|❌" "$LOG_FILE" | head -10 || echo "无明显问题")

## 📝 建议

1. 成功率 < 90% → 需要修复失败的任务
2. 有"未运行"的服务器 → 检查启动脚本
3. 重复测试失败 → 检查状态残留问题

---
🏰 城堡压力测试 | $(date '+%Y-%m-%d')
EOF

echo "" | tee -a "$LOG_FILE"
echo "📄 测试报告已生成：$SUMMARY_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 发送测试报告到飞书
echo "📤 发送测试报告到飞书..." | tee -a "$LOG_FILE"

/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🚨 压力测试报告 - $(date '+%Y-%m-%d %H:%M:%S')

📊 测试结果
━━━━━━━━━━━━━━━━━━
总测试数：${TOTAL}
成功：${SUCCESS}
失败：${FAILED}
成功率：$((SUCCESS * 100 / TOTAL))%

✅ 测试通过的功能
$(grep "✅ 成功" "$LOG_FILE" | wc -l) 项通过

❌ 测试失败的功能
$(grep "❌ 失败" "$LOG_FILE" | wc -l) 项失败

📄 详细报告：
/workspace/logs/stress-test/stress-test-${TIMESTAMP}-summary.md

🏰 城堡压力测试 | 连夜跑"

echo "" | tee -a "$LOG_FILE"
echo "✅ 压力测试全部完成！" | tee -a "$LOG_FILE"

# 如果有失败的，退出码为 1
if [ $FAILED -gt 0 ]; then
  echo "⚠️ 有 ${FAILED} 项测试失败，请检查日志" | tee -a "$LOG_FILE"
  exit 1
fi

echo "🎉 所有测试通过！" | tee -a "$LOG_FILE"
exit 0
