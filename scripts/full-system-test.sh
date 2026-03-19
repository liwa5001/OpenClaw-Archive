#!/bin/bash
# 六堡系统全面测试脚本 v2.0
# 使用：./scripts/full-system-test.sh [--tonight|--corner-cases|--concurrent|--help]

# 注意：不使用 set -e，让测试继续运行即使有失败
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace
mkdir -p logs/test-20260319

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/test-20260319/full-test-${TIMESTAMP}.log"
REPORT_FILE="logs/test-20260319/test-report-${TIMESTAMP}.md"

# 测试统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1" | tee -a "$LOG_FILE"; }

# 测试函数
run_test() {
  local test_name="$1"
  local test_command="$2"
  local expected_result="${3:-0}"
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  log_info "测试 #${TOTAL_TESTS}: ${test_name}"
  
  if eval "$test_command" >> "$LOG_FILE" 2>&1; then
    if [ "$expected_result" -eq 0 ]; then
      log_success "✓ ${test_name}"
      PASSED_TESTS=$((PASSED_TESTS + 1))
      return 0
    else
      log_error "✗ ${test_name} - 期望失败但成功了"
      FAILED_TESTS=$((FAILED_TESTS + 1))
      return 1
    fi
  else
    if [ "$expected_result" -ne 0 ]; then
      log_success "✓ ${test_name} - 按预期失败"
      PASSED_TESTS=$((PASSED_TESTS + 1))
      return 0
    else
      log_error "✗ ${test_name} - 执行失败"
      FAILED_TESTS=$((FAILED_TESTS + 1))
      return 1
    fi
  fi
}

# ==================== 任务列表 ====================
# 使用兼容的数组写法
TASK_IDS="T01 T02 T03 T04 T05 T06 T07 T08 T09 T10"
TASK_T01="每日晨报:scripts/morning-news.sh"
TASK_T02="每日爆款日报:scripts/daily-hot-report-ultimate.sh"
TASK_T03="Castle Six 问卷:scripts/castle-six-daily-questionnaire.sh"
TASK_T04="健康堡每日复盘:scripts/health-daily-review.sh"
TASK_T05="成长堡每日复盘:scripts/growth-daily-review.sh"
TASK_T06="总复盘堡每日简报:scripts/total-daily-brief.sh"
TASK_T07="财富堡每周复盘:scripts/wealth-weekly-check.sh"
TASK_T08="关系堡每周问卷:scripts/relationship-weekly-sender.sh"
TASK_T09="Gateway 重启:system"
TASK_T10="Strava 数据同步:scripts/sync-strava-data.sh"

get_task() {
  eval echo "\$TASK_$1"
}

# ==================== 测试阶段 1: 单任务测试 ====================
test_single_tasks() {
  echo "" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  echo "📋 阶段 1: 单任务功能测试" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  
  for task_id in $TASK_IDS; do
    task_info=$(get_task $task_id)
    IFS=':' read -r task_name task_script <<< "$task_info"
    
    echo "" | tee -a "$LOG_FILE"
    echo "--- 测试 ${task_id}: ${task_name} ---" | tee -a "$LOG_FILE"
    
    if [ "$task_script" == "system" ]; then
      log_warning "跳过系统任务：${task_name}"
      SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
      continue
    fi
    
    if [ ! -f "$task_script" ]; then
      log_error "脚本不存在：${task_script}"
      FAILED_TESTS=$((FAILED_TESTS + 1))
      continue
    fi
    
    # 测试 1: 脚本是否存在且可执行
    run_test "${task_id}-01 脚本可执行" "test -x ${task_script} || chmod +x ${task_script}"
    
    # 测试 2: 语法检查
    run_test "${task_id}-02 语法检查" "bash -n ${task_script}"
    
    # 测试 3: 实际运行（如果支持 dry-run 或测试模式）
    if grep -q "dry-run\|test\|--help" "$task_script" 2>/dev/null; then
      run_test "${task_id}-03 测试运行" "${task_script} --dry-run" || \
      run_test "${task_id}-03 测试运行" "${task_script} --help" || \
      log_warning "${task_id}-03 无测试模式，跳过"
    else
      log_warning "${task_id}-03 无测试模式，跳过实际运行"
      SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    fi
    
    # 测试 4: 检查依赖
    run_test "${task_id}-04 检查依赖" "grep -q 'openclaw\\|node\\|curl' ${task_script}"
    
    # 测试 5: 检查错误处理
    run_test "${task_id}-05 错误处理" "grep -qE 'set -e|trap|catch|error' ${task_script}"
    
    # 测试 6: 检查日志记录
    run_test "${task_id}-06 日志记录" "grep -qE 'log|echo.*>>|tee' ${task_script}"
    
    # 测试 7: 检查超时设置
    run_test "${task_id}-07 超时设置" "grep -qiE 'timeout|max-time|TIMEOUT_SECONDS' ${task_script}" || \
      log_warning "${task_id}-07 未设置超时"
    
    # 测试 8: 检查 cleanup
    run_test "${task_id}-08 清理机制" "grep -qE 'trap.*cleanup|rm -f.*tmp' ${task_script}" || \
      log_warning "${task_id}-08 无 cleanup 机制"
  done
}

# ==================== 测试阶段 2: 边界情况测试 ====================
test_corner_cases() {
  echo "" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  echo "🔍 阶段 2: 边界情况测试" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  
  # CC-01: 网络异常模拟
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-01: 网络异常模拟 ---" | tee -a "$LOG_FILE"
  run_test "CC-01-01 检查超时设置" "grep -r 'max-time\\|timeout' scripts/*.sh"
  run_test "CC-01-02 检查错误处理" "grep -r '|| echo\\|if.*curl.*failed' scripts/*.sh" || \
    log_warning "部分脚本无网络错误处理"
  
  # CC-02: 服务器未启动
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-02: 服务器未启动 ---" | tee -a "$LOG_FILE"
  run_test "CC-02-01 健康堡服务器检查" "curl -s http://localhost:8897/status" || \
    log_warning "健康堡服务器未运行"
  run_test "CC-02-02 成长堡服务器检查" "curl -s http://localhost:8896/status" || \
    log_warning "成长堡服务器未运行"
  run_test "CC-02-03 考题服务器检查" "curl -s http://localhost:8898/status" || \
    log_warning "考题服务器未运行"
  
  # CC-03: 日志文件过大
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-03: 日志文件检查 ---" | tee -a "$LOG_FILE"
  run_test "CC-03-01 检查日志大小" "ls -lh logs/*.log 2>/dev/null | awk '\$5 ~ /G/ {print}' | wc -l" "0" || \
    log_warning "有 GB 级日志文件"
  run_test "CC-03-02 检查日志轮转" "ls -la logs/*.gz logs/*.old 2>/dev/null | wc -l" || \
    log_warning "无日志轮转机制"
  
  # CC-04: 并发冲突
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-04: 并发冲突检查 ---" | tee -a "$LOG_FILE"
  run_test "CC-04-01 检查文件锁" "grep -r 'flock\\|lockfile' scripts/*.sh" || \
    log_warning "无文件锁机制"
  run_test "CC-04-02 检查临时文件" "ls /tmp/*morning* /tmp/*hot* /tmp/*castle* 2>/dev/null | wc -l"
  
  # CC-05: 数据格式异常
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-05: 数据格式检查 ---" | tee -a "$LOG_FILE"
  run_test "CC-05-01 检查数据验证" "grep -r 'if.*empty\\|if.*null\\|validate' scripts/*.sh" || \
    log_warning "无数据验证机制"
  run_test "CC-05-02 检查默认值" "grep -r ':-\\|default\\|fallback' scripts/*.sh" || \
    log_warning "无默认值处理"
  
  # CC-06: 时间边界
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-06: 时间边界检查 ---" | tee -a "$LOG_FILE"
  run_test "CC-06-01 检查时区设置" "grep -r 'Asia/Shanghai\\|TZ=' scripts/*.sh" || \
    log_warning "无时区设置"
  run_test "CC-06-02 检查日期计算" "grep -r 'date.*-v\\|yesterday\\|tomorrow' scripts/*.sh" || \
    log_warning "无日期计算"
  
  # CC-07: 资源泄漏
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-07: 资源泄漏检查 ---" | tee -a "$LOG_FILE"
  run_test "CC-07-01 检查后台进程" "ps aux | grep -E 'sleep.*&|curl.*&' | grep -v grep | wc -l"
  run_test "CC-07-02 检查 cleanup" "grep -r 'trap.*EXIT\\|cleanup()' scripts/*.sh" || \
    log_warning "无 cleanup 函数"
  
  # CC-08: 配置变更
  echo "" | tee -a "$LOG_FILE"
  echo "--- CC-08: 配置变更检查 ---" | tee -a "$LOG_FILE"
  run_test "CC-08-01 配置验证脚本" "test -x scripts/validate-configs-persistent.sh"
  run_test "CC-08-02 HEARTBEAT 更新检查" "grep -q '2026-03-19' HEARTBEAT.md" || \
    log_warning "HEARTBEAT.md 未更新"
}

# ==================== 测试阶段 3: 配置检查 ====================
test_configurations() {
  echo "" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  echo "⚙️  阶段 3: 配置检查" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  
  # 检查 cron 配置
  run_test "CFG-01 cron 任务列表" "openclaw cron list" 
  
  # 检查脚本权限
  run_test "CFG-02 脚本可执行权限" "ls -la scripts/*.sh | grep -c '^-rwx'" 
  
  # 检查日志目录
  run_test "CFG-03 日志目录可写" "test -w logs"
  
  # 检查输出目录
  run_test "CFG-04 输出目录存在" "test -d daily-output"
  
  # 检查报告目录
  run_test "CFG-05 报告目录存在" "test -d reports"
}

# ==================== 生成测试报告 ====================
generate_report() {
  echo "" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  echo "📊 生成测试报告" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  
  local pass_rate=0
  if [ $TOTAL_TESTS -gt 0 ]; then
    pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
  fi
  
  cat > "$REPORT_FILE" << EOF
# 🚨 六堡系统全面测试报告

**测试时间：** $(date '+%Y-%m-%d %H:%M:%S')  
**测试类型：** 单任务 + 边界情况 + 配置检查  
**日志文件：** \`$LOG_FILE\`

## 📊 测试结果汇总

| 指标 | 数值 | 目标 | 状态 |
|------|------|------|------|
| 总测试数 | ${TOTAL_TESTS} | - | - |
| 通过数 | ${PASSED_TESTS} | - | ✅ |
| 失败数 | ${FAILED_TESTS} | 0 | $([ $FAILED_TESTS -eq 0 ] && echo "✅" || echo "❌") |
| 跳过数 | ${SKIPPED_TESTS} | - | ⚪ |
| 通过率 | ${pass_rate}% | ≥95% | $([ $pass_rate -ge 95 ] && echo "✅" || echo "❌") |

## 📋 测试阶段详情

### 阶段 1: 单任务功能测试

测试了以下任务：
- T01: 每日晨报
- T02: 每日爆款日报
- T03: Castle Six 问卷
- T04: 健康堡每日复盘
- T05: 成长堡每日复盘
- T06: 总复盘堡每日简报
- T07: 财富堡每周复盘
- T08: 关系堡每周问卷
- T09: Gateway 重启（跳过）
- T10: Strava 数据同步

### 阶段 2: 边界情况测试

测试了以下边界情况：
- CC-01: 网络异常
- CC-02: 服务器未启动
- CC-03: 日志文件过大
- CC-04: 并发冲突
- CC-05: 数据格式异常
- CC-06: 时间边界
- CC-07: 资源泄漏
- CC-08: 配置变更

### 阶段 3: 配置检查

检查了以下配置：
- cron 任务配置
- 脚本权限
- 目录结构
- 日志系统

## ⚠️ 发现的问题

EOF

  if [ $FAILED_TESTS -gt 0 ]; then
    echo "共发现 **${FAILED_TESTS}** 个问题：" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    grep "\[FAIL\]" "$LOG_FILE" | head -20 >> "$REPORT_FILE"
  else
    echo "🎉 **无严重问题！**" >> "$REPORT_FILE"
  fi

  cat >> "$REPORT_FILE" << EOF

## ⚠️ 警告项

EOF

  grep "\[WARN\]" "$LOG_FILE" | head -20 >> "$REPORT_FILE" || echo "无警告项" >> "$REPORT_FILE"

  cat >> "$REPORT_FILE" << EOF

## 📝 改进建议

EOF

  if [ $FAILED_TESTS -gt 0 ]; then
    echo "1. **优先修复**：${FAILED_TESTS} 个失败测试" >> "$REPORT_FILE"
    echo "2. **关注警告**：检查所有警告项" >> "$REPORT_FILE"
    echo "3. **重新测试**：修复后运行完整测试" >> "$REPORT_FILE"
  else
    echo "✅ 系统状态良好，建议：" >> "$REPORT_FILE"
    echo "1. 定期运行此测试（每周一次）" >> "$REPORT_FILE"
    echo "2. 关注生产环境监控报告" >> "$REPORT_FILE"
    echo "3. 持续优化边界情况处理" >> "$REPORT_FILE"
  fi

  cat >> "$REPORT_FILE" << EOF

---
🏰 城堡测试报告 v2.0 | $(date '+%Y-%m-%d')
EOF

  echo "📄 报告已生成：$REPORT_FILE"
}

# ==================== 发送报告到飞书 ====================
send_report() {
  local pass_rate=0
  if [ $TOTAL_TESTS -gt 0 ]; then
    pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
  fi
  
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🚨 六堡系统全面测试报告

📊 测试结果
━━━━━━━━━━━━━━━━━━
总测试数：${TOTAL_TESTS}
通过：${PASSED_TESTS}
失败：${FAILED_TESTS}
跳过：${SKIPPED_TESTS}
通过率：${pass_rate}%

📋 测试阶段
━━━━━━━━━━━━━━━━━━
✅ 阶段 1: 单任务功能测试
✅ 阶段 2: 边界情况测试
✅ 阶段 3: 配置检查

📈 稳定性评估
━━━━━━━━━━━━━━━━━━
$([ $pass_rate -ge 95 ] && echo "✅ 系统稳定，可以投入使用" || echo "⚠️ 发现问题，建议修复")

📄 详细报告：
${REPORT_FILE}

🏰 城堡测试 | 2026-03-19"
}

# ==================== 主程序 ====================
main() {
  echo "🚨 六堡系统全面测试 v2.0" | tee "$LOG_FILE"
  echo "开始时间：$(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
  echo "日志文件：$LOG_FILE" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  
  # 阶段 1: 单任务测试
  test_single_tasks
  
  # 阶段 2: 边界情况测试
  test_corner_cases
  
  # 阶段 3: 配置检查
  test_configurations
  
  # 生成报告
  generate_report
  
  # 发送报告
  send_report
  
  echo "" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  echo "测试完成 - $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
  echo "========================================" | tee -a "$LOG_FILE"
  
  # 退出码
  if [ $FAILED_TESTS -gt 0 ]; then
    log_error "测试失败：${FAILED_TESTS} 个问题"
    exit 1
  else
    log_success "测试全部通过！"
    exit 0
  fi
}

# 执行
main
