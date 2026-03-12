#!/bin/bash
# 健康报告生成脚本 - 日报/周报/年报

set -e

# 修复 cron 环境 PATH 问题
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace

# 创建数据目录
mkdir -p data/strava reports

# 自动刷新 Strava Token
echo "🔐 检查 Strava Token 状态..."
EVAL_OUTPUT=$(./scripts/auto-refresh-strava-token.sh)
if echo "$EVAL_OUTPUT" | grep -q "EXPORT_TOKENS=1"; then
  eval "$(echo "$EVAL_OUTPUT" | grep "^STRAVA_")"
  echo "✅ Token 已就绪"
else
  echo "❌ Token 刷新失败"
  exit 1
fi
echo ""

# 获取 Strava 运动数据
fetch_strava_activities() {
  local per_page=${1:-30}
  curl -s -G "https://www.strava.com/api/v3/athlete/activities" \
    -H "Authorization: Bearer $STRAVA_TOKEN" \
    -d "per_page=$per_page"
}

# 生成日报
generate_daily_report() {
  local yesterday=$(date -d "yesterday" +%Y-%m-%d)
  local today=$(date +%Y-%m-%d)
  
  echo "📊 生成日报 - $today"
  
  # 获取最近运动
  local activities=$(fetch_strava_activities 5)
  
  # 简单解析（实际应该用 Python/Node.js 解析 JSON）
  local activity_count=$(echo "$activities" | grep -c '"type"' || echo "0")
  
  # 生成报告
  cat << EOF
📰 健康日报 - $today

🏃 昨日运动
$(if [ "$activity_count" -gt 0 ]; then
  echo "有 $activity_count 次运动记录"
  echo "详情见 Strava App"
else
  echo "昨天休息，今天继续加油！💪"
fi)

📋 今日训练计划
$(cat << PLAN
- 查看 training-reminder.sh 获取今日训练
- 运动前 1 小时会收到提醒
PLAN
)

💡 健康提示
- 保持充足睡眠（7-8 小时）
- 运动前后注意拉伸
- 及时补充水分

---
🏰 城堡健康追踪
EOF
}

# 生成周报
generate_weekly_report() {
  local week_start=$(date -d "last Monday" +%Y-%m-%d)
  local week_end=$(date -d "Sunday" +%Y-%m-%d)
  local today=$(date +%Y-%m-%d)
  
  echo "📈 生成周报 - $today"
  
  # 获取最近 30 次运动（覆盖一周）
  local activities=$(fetch_strava_activities 30)
  
  # 保存到文件
  echo "$activities" > "data/strava/week-$(date +%Y-W%V).json"
  
  cat << EOF
📰 健康周报 - ${week_start} 至 ${week_end}

🚴 本周运动统计
- 运动次数：统计中...
- 总距离：统计中...
- 总时间：统计中...
- 平均心率：统计中...

📊 训练进度
- 第 X 周 / 12 周
- 本周目标：完成 X km
- 实际完成：统计中...

💓 心率分析
- 平均静息心率：待华为数据接入
- 运动平均心率：统计中...

🎯 下周计划
- 继续基础耐力训练
- 逐步增加长距离

---
🏰 城堡健康追踪
EOF
}

# 生成年报
generate_yearly_report() {
  local year=$(date +%Y)
  
  echo "📉 生成年报 - $year"
  
  cat << EOF
📰 健康年报 - $year 年度总结

🎉 年度成就
- 总运动次数：待统计
- 总骑行距离：待统计
- 最长单次骑行：待统计
- 平均每周运动：待统计

📊 年度最佳
- 最快骑行：待统计
- 最长距离：待统计
- 最高功率：待统计

💓 健康变化
- 年初体重：80 kg
- 年末体重：待记录
- 静息心率变化：待华为数据

🎯 下一年目标
- 完成 100 km 骑行
- 保持每周运动 3 次+
- 提升有氧耐力

---
🏰 城堡健康追踪
EOF
}

# 发送报告到飞书
send_to_feishu() {
  local report="$1"
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$report"
}

# 发送报告到飞书
send_to_feishu() {
  local report="$1"
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$report"
}

# 主函数
case "${1:-daily}" in
  daily)
    REPORT=$(generate_daily_report)
    echo "$REPORT"
    send_to_feishu "$REPORT"
    ;;
  weekly)
    REPORT=$(generate_weekly_report)
    echo "$REPORT"
    send_to_feishu "$REPORT"
    ;;
  yearly)
    REPORT=$(generate_yearly_report)
    echo "$REPORT"
    send_to_feishu "$REPORT"
    ;;
  *)
    echo "用法：$0 {daily|weekly|yearly}"
    exit 1
    ;;
esac
