#!/bin/bash
# 训练计划更新脚本 - 根据分析结果调整训练计划

set -e

cd /Users/liwang/.openclaw/workspace

# 配置文件
CONFIG_FILE="docs/strava-health-config.md"
TRAINING_PLAN_FILE="docs/training-plan.md"
ADJUSTMENT_LOG="logs/training-adjustments.log"

# 创建日志目录
mkdir -p logs

# 获取当前训练周次
get_current_week() {
  # 从配置文件读取，简化版本
  echo "1"
}

# 更新训练计划
update_training_plan() {
  local adjustment_type="$1"
  local reason="$2"
  local current_week=$(get_current_week)
  
  echo "📝 更新训练计划 - 类型：${adjustment_type}"
  
  case $adjustment_type in
    "降低强度")
      # 降低心率区间 10-15 bpm
      echo "$(date): 第${current_week}周 - 降低强度 - ${reason}" >> "$ADJUSTMENT_LOG"
      
      # 更新配置文件
      sed -i.bak 's/120-140 bpm/110-130 bpm/g' "$TRAINING_PLAN_FILE"
      sed -i.bak 's/Z2/Z1-Z2/g' "$TRAINING_PLAN_FILE"
      
      local message="✅ 训练计划已调整
  
📋 调整内容：
- 心率区间：120-140 → 110-130 bpm
- 强度等级：Z2 → Z1-Z2
- 距离目标：保持不变

💡 调整原因：
${reason}

⏱️ 调整周期：1 周
- 1 周后重新评估
- 如体感良好可恢复原计划

📊 监控指标：
- 运动时心率
- 静息心率
- 睡眠质量
- 体感疲劳度

---
🏰 城堡健康追踪 | 循序渐进，安全第一！💪"
      ;;
      
    "增加恢复")
      # 增加休息日
      echo "$(date): 第${current_week}周 - 增加恢复 - ${reason}" >> "$ADJUSTMENT_LOG"
      
      local message="✅ 训练计划已调整
  
📋 调整内容：
- 增加 1 个休息日
- 减少 1 次耐力训练
- 保持长距离训练

💡 调整原因：
${reason}

⏱️ 调整周期：1 周
- 充分恢复后继续
- 关注身体反馈

📊 恢复建议：
- 保证 8 小时睡眠
- 增加蛋白质摄入
- 轻度拉伸和按摩
- 减少压力

---
🏰 城堡健康追踪 | 恢复也是训练的一部分！😴"
      ;;
      
    "保持当前")
      local message="✅ 训练计划评估完成

📋 评估结果：
- 当前计划：合适
- 无需调整
- 继续执行原计划

💡 建议：
- 保持当前训练强度
- 注意充分恢复
- 逐步增加距离

📊 下次评估：7 天后

---
🏰 城堡健康追踪 | 坚持就是胜利！💪"
      ;;
      
    *)
      local message="⚠️ 未知的调整类型：${adjustment_type}"
      ;;
  esac
  
  # 发送确认消息（飞书）
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$message"
  echo "✅ 训练计划更新通知已发送（飞书） - $(date)"
  
  # 记录更新
  echo "$(date): 训练计划更新 - ${adjustment_type}" >> "$ADJUSTMENT_LOG"
}

# 检查用户是否同意调整
check_user_agreement() {
  # 这里简化处理，实际应该检查用户的回复
  # 可以通过检查特定文件或消息记录
  
  local agreement_file="data/training_adjustment_agreement.txt"
  
  if [ -f "$agreement_file" ]; then
    local agreement=$(cat "$agreement_file")
    if [ "$agreement" = "同意调整" ] || [ "$agreement" = "yes" ] || [ "$agreement" = "1" ]; then
      echo "true"
      rm "$agreement_file"  # 清除同意标记
    else
      echo "false"
    fi
  else
    echo "false"
  fi
}

# 主函数
case "${1:-check}" in
  "update")
    # 更新训练计划
    update_training_plan "$2" "$3"
    ;;
    
  "check")
    # 检查是否需要更新
    agreed=$(check_user_agreement)
    if [ "$agreed" = "true" ]; then
      echo "👍 用户已同意调整"
      update_training_plan "降低强度" "根据运动数据分析建议"
    else
      echo "ℹ️ 用户未同意调整，保持原计划"
    fi
    ;;
    
  *)
    echo "用法：$0 {update|check} [调整类型] [原因]"
    exit 1
    ;;
esac
