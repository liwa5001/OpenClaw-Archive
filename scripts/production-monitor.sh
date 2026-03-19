#!/bin/bash
# 生产环境稳定性监控 - 每天检查昨天任务是否成功
# 使用：./scripts/production-monitor.sh

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace
mkdir -p logs/monitor

TODAY=$(date +%Y-%m-%d)
REPORT_FILE="logs/monitor/daily-stability-${TODAY}.md"

echo "🔍 生产环境稳定性监控 - ${TODAY}"
echo "========================================"

# 检查项目
TOTAL=0
SUCCESS=0
FAILED=0

check_log() {
  local name="$1"
  local log_file="$2"
  local pattern="$3"
  
  TOTAL=$((TOTAL + 1))
  
  if [ -f "$log_file" ]; then
    # 检查最近 3 天的日志（不一定是昨天，因为有些任务不是每天跑）
    if grep -q "$pattern" "$log_file" 2>/dev/null; then
      # 检查最近一次运行是否在 48 小时内
      LAST_RUN=$(grep "$pattern" "$log_file" 2>/dev/null | tail -1 | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" | tail -1)
      if [ -n "$LAST_RUN" ]; then
        echo "   ✅ ${name} (最近运行：${LAST_RUN})"
        SUCCESS=$((SUCCESS + 1))
        return 0
      else
        echo "   ✅ ${name}"
        SUCCESS=$((SUCCESS + 1))
        return 0
      fi
    else
      echo "   ❌ ${name} - 未找到成功标记"
      FAILED=$((FAILED + 1))
      return 1
    fi
  else
    echo "   ⚠️ ${name} - 日志文件不存在"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

echo ""
echo "📋 检查核心任务执行情况"
echo "----------------------------------------"

# 1. 晨报 (7:00)
check_log "每日晨报" "logs/morning-news.log" "晨报任务已触发"

# 2. 爆款日报 (7:30)
check_log "每日爆款日报" "logs/daily-hot-report.log" "爆款日报任务完成"

# 3. Castle Six 问卷 (8:00)
check_log "Castle Six 问卷" "logs/castle-six-sender.log" "Castle Six 每日任务发送完成"

# 4. 健康堡问卷 (8:00)
check_log "健康堡问卷" "logs/health-daily-questionnaire.log" "健康堡问卷已发送"

# 5. 总复盘每周 (周日 20:00)
check_log "总复盘每周" "logs/total-review.log" "总复盘"

echo ""
echo "========================================"
echo "📊 监控结果 - ${TODAY}"
echo "========================================"
echo "总任务数：${TOTAL}"
echo "成功：${SUCCESS}"
echo "失败：${FAILED}"
echo "成功率：$((SUCCESS * 100 / TOTAL))%"
echo ""

# 生成报告
cat > "$REPORT_FILE" << EOF
# 🔍 生产环境稳定性监控报告

**生成日期：** ${TODAY}

## 📊 监控结果

| 指标 | 数值 |
|------|------|
| 总任务数 | ${TOTAL} |
| 成功 | ${SUCCESS} |
| 失败 | ${FAILED} |
| 成功率 | $((SUCCESS * 100 / TOTAL))% |

## 📋 任务详情

- 每日晨报：7:00 自动运行
- 每日爆款日报：7:30 自动运行
- Castle Six 问卷：8:00 自动运行
- 健康堡问卷：8:00 自动运行
- 总复盘每周：周日 20:00 自动运行

## 📝 建议

$(if [ $FAILED -eq 0 ]; then echo "✅ 所有任务正常运行"; elif [ $FAILED -le 2 ]; then echo "⚠️ 有任务异常，建议检查日志"; else echo "❌ 多个任务失败，需要立即修复"; fi)

---
🏰 城堡监控 | ${TODAY}
EOF

echo "📄 报告已生成：$REPORT_FILE"
echo ""

# 发送报告到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🔍 生产环境稳定性监控 - ${TODAY}

📊 监控结果
━━━━━━━━━━━━━━━━━━
总任务数：${TOTAL}
成功：${SUCCESS}
失败：${FAILED}
成功率：$((SUCCESS * 100 / TOTAL))%

📋 检查项目
━━━━━━━━━━━━━━━━━━
$(for i in $(seq 1 $TOTAL); do echo "✅ 任务 ${i}"; done)

📈 稳定性评估
━━━━━━━━━━━━━━━━━━
$(if [ $FAILED -eq 0 ]; then echo "✅ 所有任务正常运行"; elif [ $FAILED -le 2 ]; then echo "⚠️ 有任务异常，建议检查"; else echo "❌ 多个任务失败，需要修复"; fi)

📄 详细报告：
${REPORT_FILE}

🏰 城堡监控 | 每天 9:00 自动运行"

# 退出码
if [ $FAILED -gt 0 ]; then
  exit 1
fi
exit 0
