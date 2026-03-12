#!/bin/bash
# 运动数据分析脚本 - 分析昨日运动数据并提供训练建议

set -e

cd /Users/liwang/.openclaw/workspace

# 创建数据目录
mkdir -p data/strava reports/analysis

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

# 获取昨天的日期
YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

# 发送 Token 过期错误报告
send_token_error_report() {
  local weekday=$(date +%u)
  local today_plan=""
  
  case $weekday in
    2|4) today_plan="- 基础耐力骑行 30km" ;;
    3) today_plan="- 恢复骑行 20km" ;;
    6) today_plan="- 长距离骑行 40km" ;;
    *) today_plan="- 休息日" ;;
  esac
  
  cat << EOF > "reports/analysis/analysis-${YESTERDAY}-error.txt"
⚠️ 运动数据分析 - 数据同步失败

🔐 问题说明
Strava API 授权失败，无法获取运动数据

📋 可能原因
1. Strava Token 已过期（需要重新授权）
2. Strava 应用权限被撤销

🔧 解决方案
请重新获取 Strava Access Token：
1. 访问 Strava API 设置页面
2. 生成新的 Access Token
3. 更新脚本中的 STRAVA_TOKEN 变量

或者运行：
cd /workspace && ./scripts/refresh-strava-token.sh

📊 今日训练计划（正常执行）
${today_plan}

---
🏰 城堡健康追踪 | 请修复 Token 配置
EOF

  # 发送到飞书
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$(cat "reports/analysis/analysis-${YESTERDAY}-error.txt")"
  echo "✅ 错误报告已发送（飞书） - $(date)"
}

# 获取 Strava 运动数据
fetch_strava_activities() {
  local per_page=${1:-10}
  local response=$(curl -s -G "https://www.strava.com/api/v3/athlete/activities" \
    -H "Authorization: Bearer $STRAVA_TOKEN" \
    -d "per_page=$per_page")
  
  # 检查是否授权错误
  if echo "$response" | grep -q "Authorization Error"; then
    echo "ERROR_AUTH"
    return 1
  fi
  
  echo "$response"
}

# 分析运动数据
analyze_yesterday_workout() {
  echo "📊 分析昨日运动数据 - $YESTERDAY"
  
  # 获取最近 10 次运动
  local activities=$(fetch_strava_activities 10)
  
  # 检查授权错误
  if [ "$activities" = "ERROR_AUTH" ]; then
    echo "⚠️ Strava Token 已过期，无法获取运动数据"
    send_token_error_report
    return 1
  fi
  
  # 保存原始数据
  echo "$activities" > "data/strava/activities-$(date +%Y%m%d).json"
  
  # 检查是否有昨天的运动
  local has_workout=$(echo "$activities" | grep -c "$YESTERDAY" || echo "0")
  
  if [ "$has_workout" -eq 0 ]; then
    echo "ℹ️ 昨天没有运动记录"
    return 0
  fi
  
  # 提取运动数据（简化版）
  local activity_name=$(echo "$activities" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
  local activity_type=$(echo "$activities" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
  local distance=$(echo "$activities" | grep -o '"distance":[0-9.]*' | head -1 | cut -d':' -f2)
  local moving_time=$(echo "$activities" | grep -o '"moving_time":[0-9]*' | head -1 | cut -d':' -f2)
  local avg_hr=$(echo "$activities" | grep -o '"average_heartrate":[0-9.]*' | head -1 | cut -d':' -f2)
  local max_hr=$(echo "$activities" | grep -o '"max_heartrate":[0-9.]*' | head -1 | cut -d':' -f2)
  local avg_watts=$(echo "$activities" | grep -o '"average_watts":[0-9.]*' | head -1 | cut -d':' -f2)
  
  # 转换距离为 km
  local distance_km=$(echo "scale=1; $distance / 1000" | bc)
  
  # 转换时间为分钟
  local time_min=$(echo "scale=0; $moving_time / 60" | bc)
  
  echo "✅ 找到运动记录："
  echo "   名称：$activity_name"
  echo "   类型：$activity_type"
  echo "   距离：${distance_km} km"
  echo "   时间：${time_min} 分钟"
  echo "   平均心率：$avg_hr bpm"
  echo "   最大功率：$avg_watts W"
  
  # 生成分析报告
  generate_analysis_report "$activity_name" "$activity_type" "$distance_km" "$time_min" "$avg_hr" "$max_hr" "$avg_watts"
}

# 生成分析报告和建议
generate_analysis_report() {
  local name="$1"
  local type="$2"
  local distance="$3"
  local time="$4"
  local avg_hr="$5"
  local max_hr="$6"
  local avg_watts="$7"
  
  # 获取当前训练周次（从配置读取）
  local week=1  # 简化，实际应该从配置文件读取
  
  # 获取今日计划
  local weekday=$(date +%u)
  local today_plan=""
  local today_distance=""
  local today_hr_zone=""
  
  case $weekday in
    2|4) today_plan="基础耐力骑行"; today_distance="30"; today_hr_zone="120-140" ;;
    3) today_plan="恢复骑行"; today_distance="20"; today_hr_zone="100-120" ;;
    6) today_plan="长距离骑行"; today_distance="40"; today_hr_zone="110-135" ;;
    *) today_plan="休息"; today_distance="0"; today_hr_zone="-" ;;
  esac
  
  # 分析表现
  local performance="良好"
  local adjustment_needed="否"
  local adjustment_reason=""
  
  # 心率分析
  if [ -n "$avg_hr" ] && [ "$avg_hr" != "null" ]; then
    if (( $(echo "$avg_hr > 145" | bc -l) )); then
      performance="偏高"
      adjustment_needed="是"
      adjustment_reason="平均心率过高，建议降低强度"
    elif (( $(echo "$avg_hr < 110" | bc -l) )); then
      performance="偏低"
      adjustment_reason="平均心率偏低，可以适当增加强度"
    fi
  fi
  
  # 距离分析
  if [ -n "$distance" ] && [ "$distance" != "null" ]; then
    if (( $(echo "$distance < 20" | bc -l) )); then
      performance="距离偏短"
      adjustment_reason="完成距离低于目标，建议保持当前计划"
    fi
  fi
  
  # 生成报告
  local REPORT="📊 运动数据分析 - $YESTERDAY

🏃 运动记录
- 名称：${name}
- 类型：${type}
- 距离：${distance} km
- 时间：${time} 分钟
$(if [ -n "$avg_hr" ] && [ "$avg_hr" != "null" ]; then
  echo "- 平均心率：${avg_hr} bpm"
  echo "- 最大心率：${max_hr} bpm"
fi)
$(if [ -n "$avg_watts" ] && [ "$avg_watts" != "null" ]; then
  echo "- 平均功率：${avg_watts} W"
fi)

📈 表现评估
- 整体表现：${performance}
- 心率区间：$(if [ -n "$avg_hr" ]; then
    if (( $(echo "$avg_hr >= 120 && $avg_hr <= 140" | bc -l) )); then
      echo "✅ 在有氧区间 (Z2)"
    else
      echo "⚠️ 偏离目标区间"
    fi
  else
    echo "无心率数据"
  fi)
- 完成度：$(if [ -n "$distance" ]; then
    if (( $(echo "$distance >= 25" | bc -l) )); then
      echo "✅ 完成目标"
    else
      echo "⚠️ 未达目标"
    fi
  else
    echo "无数据"
  fi)

💡 训练建议
$(if [ "$adjustment_needed" = "是" ]; then
  echo "⚠️ 建议调整训练计划"
  echo "原因：${adjustment_reason}"
  echo ""
  echo "调整方案："
  echo "1. 降低强度 10-15%"
  echo "2. 增加恢复时间"
  echo "3. 关注心率和体感"
  echo ""
  echo "👉 回复'同意调整'以更新训练计划"
else
  echo "✅ 当前训练计划合适"
  echo "建议："
  echo "1. 继续保持当前强度"
  echo "2. 注意充分恢复"
  echo "3. 逐步增加距离"
fi)

📋 今日训练
- 内容：${today_plan}
- 目标距离：${today_distance} km
- 目标心率：${today_hr_zone} bpm

---
🏰 城堡健康追踪 | 科学训练，持续进步！💪"

  # 保存报告
  echo "$REPORT" > "reports/analysis/analysis-${YESTERDAY}.txt"
  
  # 发送报告（飞书）
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$REPORT"
  echo "✅ 分析报告已发送（飞书） - $(date)"
  
  # 如果需要调整，记录到日志
  if [ "$adjustment_needed" = "是" ]; then
    echo "$(date): 建议调整训练计划 - ${adjustment_reason}" >> logs/training-adjustments.log
  fi
}

# 主函数
echo "🔍 开始分析昨日运动数据 - $(date)"
analyze_yesterday_workout
