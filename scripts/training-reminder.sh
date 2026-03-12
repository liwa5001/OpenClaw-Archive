#!/bin/bash
# 训练提醒脚本 - 每天两次提醒
# 1. 提前一天晚上 8 点（预告明天训练）
# 2. 当天早上 8 点（提醒今天训练）

set -e

# 修复 cron 环境 PATH 问题
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace

# 获取当前时间
NOW_HOUR=$(date +%H)
TODAY=$(date +%Y-%m-%d)
# macOS 计算明天
TOMORROW=$(date -v+1d +%Y-%m-%d)
WEEKDAY=$(date +%u)  # 1=周一，7=周日
WEEKDAY_TOMORROW=$(( (WEEKDAY % 7) + 1 ))

# 获取天气（简化版，实际可以调用天气 API）
get_weather_tips() {
  # 这里简化处理，实际可以调用 wttr.in
  local season=$(date +%m)
  if [ "$season" -ge 3 ] && [ "$season" -le 5 ]; then
    echo "🌸 春季多风，注意保暖和防风"
  elif [ "$season" -ge 6 ] && [ "$season" -le 8 ]; then
    echo "☀️ 夏季炎热，注意防暑和补水"
  elif [ "$season" -ge 9 ] && [ "$season" -le 11 ]; then
    echo "🍂 秋季凉爽，注意温差变化"
  else
    echo "❄️ 冬季寒冷，注意保暖和热身"
  fi
}

# 获取训练计划
get_training_plan() {
  local day=$1
  case $day in
    1) # 周一 - 休息日
      echo "休息日|休息|-|-|-|今天好好休息，为下周训练做准备！💪|充分睡眠、轻度拉伸、补充营养"
      ;;
    2) # 周二 - 基础耐力
      echo "基础耐力骑行|30 km|Z2|120-140 bpm|1-1.5 小时|保持有氧区间，不要过快！热身 10 分钟，冷身 5 分钟。🚴|检查胎压、准备 2 瓶水、带能量棒、手机充满电"
      ;;
    3) # 周三 - 恢复骑行
      echo "恢复骑行|20 km|Z1|100-120 bpm|45-60 分钟|轻松骑行，促进恢复。可以聊天说话的程度。😊|轻便装备、1 瓶水、无需带太多能量"
      ;;
    4) # 周四 - 基础耐力
      echo "基础耐力骑行|30 km|Z2|120-140 bpm|1-1.5 小时|保持稳定的节奏，注意补充水分。💧|检查刹车、准备 2 瓶水、带能量棒"
      ;;
    5) # 周五 - 休息日
      echo "休息日|休息|-|-|-|明天长距离，今晚早点休息！😴|早睡、准备好明天装备、检查天气预报"
      ;;
    6) # 周六 - 长距离（重点）
      echo "长距离骑行（重点训练）|40 km|Z2|110-135 bpm|2-3 小时|本周重点训练！带足水和能量，注意 pacing，不要一开始太快。🎯|检查全车、准备 3-4 瓶水、带 2 个能量棒、带备用内胎、告知家人路线"
      ;;
    7) # 周日 - 主动恢复
      echo "主动恢复|轻度活动|Z1|100-120 bpm|30-60 分钟|散步、拉伸或完全休息。让身体恢复！🧘|轻松活动、瑜伽、泡沫轴放松"
      ;;
  esac
}

# 解析训练计划
parse_training() {
  local plan="$1"
  IFS='|' read -r NAME DISTANCE INTENSITY HEART_RATE DURATION NOTE PREP <<< "$plan"
}

# 发送晚间提醒（提前一天）
send_evening_reminder() {
  local plan=$(get_training_plan $WEEKDAY_TOMORROW)
  parse_training "$plan"
  
  # 计算日期
  local tomorrow_weekday_name=""
  case $WEEKDAY_TOMORROW in
    1) tomorrow_weekday_name="周一" ;;
    2) tomorrow_weekday_name="周二" ;;
    3) tomorrow_weekday_name="周三" ;;
    4) tomorrow_weekday_name="周四" ;;
    5) tomorrow_weekday_name="周五" ;;
    6) tomorrow_weekday_name="周六" ;;
    7) tomorrow_weekday_name="周日" ;;
  esac
  
  local weather_tips=$(get_weather_tips)
  
  local MESSAGE="🌙 明日训练预告 - $TOMORROW ($tomorrow_weekday_name)

📋 训练内容：${NAME}
📏 距离：${DISTANCE}
💪 强度：${INTENSITY}
💓 心率：${HEART_RATE}
⏱️ 时长：${DURATION}

💡 训练提示：
${NOTE}

⚠️ 注意事项：
1. 训练前 2 小时进食（高碳水）
2. 训练前 30 分钟补充能量（香蕉/能量棒）
3. 全程保持心率在目标区间
4. 如有不适立即停止休息
5. 训练后 30 分钟内补充蛋白质

🎒 准备清单：
${PREP}

🔧 自行车检查（5 分钟）：
- [ ] 轮胎气压（60 PSI 左右）
- [ ] 刹车是否正常
- [ ] 链条润滑
- [ ] 变速顺畅

🪖 骑行装备：
- [ ] 头盔（安全第一）
- [ ] 骑行眼镜（防风防虫）
- [ ] 心率带（监测数据）
- [ ] 锁鞋（如使用自锁）

🌤️ 天气提示：
${weather_tips}

📱 安全提醒：
- 告知家人骑行路线
- 携带身份证和紧急联系人
- 遵守交通规则
- 佩戴头盔和骑行服

---
🏰 城堡健康追踪 | 晚安，明天见！😴"

  # 发送到飞书
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE"
  echo "✅ 晚间提醒已发送（飞书） - $(date)"
}

# 发送当天提醒（提前一小时）
send_morning_reminder() {
  local plan=$(get_training_plan $WEEKDAY)
  parse_training "$plan"
  
  local today_weekday_name=""
  case $WEEKDAY in
    1) today_weekday_name="周一" ;;
    2) today_weekday_name="周二" ;;
    3) today_weekday_name="周三" ;;
    4) today_weekday_name="周四" ;;
    5) today_weekday_name="周五" ;;
    6) today_weekday_name="周六" ;;
    7) today_weekday_name="周日" ;;
  esac
  
  local weather_tips=$(get_weather_tips)
  
  local MESSAGE="🚴 训练提醒 - $TODAY ($today_weekday_name)

📋 今日训练：${NAME}
📏 距离：${DISTANCE}
💪 强度：${INTENSITY}
💓 心率：${HEART_RATE}
⏱️ 时长：${DURATION}

💡 训练提示：${NOTE}

🔥 热身流程（10 分钟）：
1. 轻松骑行 5 分钟（Z1）
2. 动态拉伸 3 分钟
   - 腿部摆动 × 10
   - 手臂绕环 × 10
   - 腰部转动 × 10
3. 几次短加速 2 分钟
   - 30 秒加速 + 30 秒放松 × 3

🧘 冷身流程（5 分钟）：
1. 慢骑 3 分钟（Z1）
2. 静态拉伸 2 分钟
   - 大腿前侧 × 30 秒
   - 大腿后侧 × 30 秒
   - 小腿 × 30 秒

🍎 营养建议：
- 训练前 2 小时：米饭/面条
- 训练前 30 分钟：香蕉 + 能量棒
- 每小时补充：500-750ml 水
- 训练后 30 分钟：蛋白质 + 碳水

🌤️ 天气提示：
${weather_tips}

---
🏰 城堡健康追踪 | 加油！💪"

  # 发送到飞书
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE"
  echo "✅ 当天提醒已发送（飞书） - $(date)"
}

# 主逻辑
echo "🔔 训练提醒检查 - $(date)"

# 晚上 8 点发送明天预告 (20:00)
if [ "$NOW_HOUR" -eq 20 ]; then
  send_evening_reminder
fi

# 早上 8 点发送当天提醒 (08:00)
if [ "$NOW_HOUR" -eq 8 ]; then
  send_morning_reminder
fi

# 如果是手动运行，发送两次测试
if [ "$1" = "test" ]; then
  echo "🧪 测试模式：发送两次提醒"
  send_evening_reminder
  sleep 2
  send_morning_reminder
fi
