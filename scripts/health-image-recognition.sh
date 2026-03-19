#!/bin/bash
# 健康堡图片数据识别脚本
# 识别华为睡眠截图、三餐照片，自动保存数据

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace
mkdir -p logs health-data/images

LOG_FILE="logs/health-image-recognition.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 参数：图片 URL 或本地路径
IMAGE_URL="$1"
IMAGE_TYPE="$2"  # sleep, breakfast, lunch, dinner, weight

if [ -z "$IMAGE_URL" ]; then
    log "❌ 错误：请提供图片 URL"
    exit 1
fi

log "=== 健康数据图片识别开始 ==="
log "图片：$IMAGE_URL"
log "类型：$IMAGE_TYPE"

# 下载图片到临时文件
TEMP_IMAGE="/tmp/health-data-$(date +%s).jpg"
curl -L -o "$TEMP_IMAGE" "$IMAGE_URL" 2>/dev/null || cp "$IMAGE_URL" "$TEMP_IMAGE"

if [ ! -f "$TEMP_IMAGE" ] || [ ! -s "$TEMP_IMAGE" ]; then
    log "❌ 错误：图片下载失败"
    exit 1
fi

log "✅ 图片已下载到 $TEMP_IMAGE"

# 调用视觉模型识别
log "🔍 调用视觉模型识别..."

# 根据类型选择识别提示词
case $IMAGE_TYPE in
    sleep)
        PROMPT="这是一张华为健康 App 的睡眠数据截图。请识别以下信息：
1. 日期（格式：YYYY-MM-DD）
2. 入睡时间
3. 起床时间
4. 睡眠总时长
5. 深睡时长
6. 浅睡时长
7. REM 快速眼动时长
8. 清醒次数或清醒时长
9. 静息心率（如果有显示）

请以 JSON 格式返回，例如：
{
  \"date\": \"2026-03-19\",
  \"sleep_start\": \"23:30\",
  \"sleep_end\": \"07:00\",
  \"total_duration\": \"7h30m\",
  \"deep_sleep\": \"1h20m\",
  \"light_sleep\": \"5h10m\",
  \"rem_sleep\": \"1h00m\",
  \"awake_times\": 2,
  \"resting_heart_rate\": 52
}"
        ;;
    breakfast|lunch|dinner)
        PROMPT="这是一张${IMAGE_TYPE}的照片。请识别：
1. 食物名称（尽可能详细）
2. 估算份量（如：1 碗、2 个、100g 等）
3. 如果有明显的主食、蛋白质、蔬菜，请分别标注

请以 JSON 格式返回，例如：
{
  \"meal_type\": \"breakfast\",
  \"date\": \"2026-03-19\",
  \"foods\": [
    {\"name\": \"燕麦粥\", \"amount\": \"1 碗\"},
    {\"name\": \"鸡蛋\", \"amount\": \"2 个\"},
    {\"name\": \"苹果\", \"amount\": \"1 个\"}
  ]
}"
        ;;
    weight)
        PROMPT="这是一张体重秤的照片。请识别：
1. 日期（如果显示）
2. 体重数值（kg）
3. 如果有其他数据（体脂率、BMI 等）也请识别

请以 JSON 格式返回，例如：
{
  \"date\": \"2026-03-19\",
  \"weight\": 65.5,
  \"body_fat\": 18.2,
  \"bmi\": 22.1
}"
        ;;
    *)
        log "❌ 错误：未知的图片类型 $IMAGE_TYPE"
        rm -f "$TEMP_IMAGE"
        exit 1
        ;;
esac

# 调用视觉模型（使用 qwen-portal 的 vision-model）
RESULT=$(openclaw agent --session-id "health-vision-recognize" --model "qwen-portal/vision-model" --message "$PROMPT" --attachment "$TEMP_IMAGE" 2>/dev/null | grep -v "^\[plugins\]" | grep -v "^Registered" | tail -1)

log "✅ 识别完成"
log "结果：$RESULT"

# 保存识别结果
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="health-data/recognized/$(date +%Y-%m)/$(date +%Y-%m-%d)-${IMAGE_TYPE}-${TIMESTAMP}.json"
mkdir -p "$(dirname "$RESULT_FILE")"
echo "$RESULT" > "$RESULT_FILE"

log "📁 结果已保存：$RESULT_FILE"

# 提取日期（从识别结果或图片文件名）
RECOGNIZED_DATE=$(echo "$RESULT" | grep -o '"date"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([0-9-]*\)".*/\1/')

if [ -z "$RECOGNIZED_DATE" ]; then
    # 如果识别失败，使用今天
    RECOGNIZED_DATE=$(date +%Y-%m-%d)
    log "⚠️ 未识别到日期，使用今天：$RECOGNIZED_DATE"
else
    log "✅ 识别日期：$RECOGNIZED_DATE"
fi

# 根据类型保存到不同的数据文件
case $IMAGE_TYPE in
    sleep)
        # 保存到睡眠数据文件
        SLEEP_FILE="daily-output/health/sleep-data/${RECOGNIZED_DATE}-sleep.md"
        mkdir -p "$(dirname "$SLEEP_FILE")"
        
        cat > "$SLEEP_FILE" << EOF
# 睡眠数据 - $RECOGNIZED_DATE

**数据来源：** 华为健康 App 截图（AI 识别）
**识别时间：** $(date '+%Y-%m-%d %H:%M:%S')

## 睡眠详情

| 项目 | 数值 |
|------|------|
| 入睡时间 | $(echo "$RESULT" | grep -o '"sleep_start"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/') |
| 起床时间 | $(echo "$RESULT" | grep -o '"sleep_end"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/') |
| 总时长 | $(echo "$RESULT" | grep -o '"total_duration"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/') |
| 深睡 | $(echo "$RESULT" | grep -o '"deep_sleep"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/') |
| 浅睡 | $(echo "$RESULT" | grep -o '"light_sleep"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/') |
| REM | $(echo "$RESULT" | grep -o '"rem_sleep"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/') |
| 清醒次数 | $(echo "$RESULT" | grep -o '"awake_times"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:[[:space:]]*//') |
| 静息心率 | $(echo "$RESULT" | grep -o '"resting_heart_rate"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:[[:space:]]*//') bpm |

## 原始识别结果

\`\`\`json
$RESULT
\`\`\`
EOF
        log "✅ 睡眠数据已保存：$SLEEP_FILE"
        
        # 发送确认消息到飞书
        openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "✅ 睡眠数据识别完成

📅 日期：$RECOGNIZED_DATE
😴 入睡：$(echo "$RESULT" | grep -o '"sleep_start"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/')
⏰ 起床：$(echo "$RESULT" | grep -o '"sleep_end"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/')
💤 总时长：$(echo "$RESULT" | grep -o '"total_duration"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)".*/\1/')
💓 静息心率：$(echo "$RESULT" | grep -o '"resting_heart_rate"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:[[:space:]]*//') bpm

数据已保存到健康堡归档。" 2>/dev/null || log "⚠️ 飞书通知发送失败"
        ;;
    
    breakfast|lunch|dinner)
        MEAL_NAME_CN=""
        case $IMAGE_TYPE in
            breakfast) MEAL_NAME_CN="早餐" ;;
            lunch) MEAL_NAME_CN="午餐" ;;
            dinner) MEAL_NAME_CN="晚餐" ;;
        esac
        
        MEAL_FILE="daily-output/health/meal-data/${RECOGNIZED_DATE}-${IMAGE_TYPE}.md"
        mkdir -p "$(dirname "$MEAL_FILE")"
        
        cat > "$MEAL_FILE" << EOF
# ${MEAL_NAME_CN} - $RECOGNIZED_DATE

**数据来源：** 照片（AI 识别）
**识别时间：** $(date '+%Y-%m-%d %H:%M:%S')

## 食物清单

$(echo "$RESULT" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"name"[[:space:]]*:[[:space:]]*"\([^"]*\)"/- \1/g')

## 原始识别结果

\`\`\`json
$RESULT
\`\`\`
EOF
        log "✅ ${MEAL_NAME_CN}数据已保存：$MEAL_FILE"
        
        openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "✅ ${MEAL_NAME_CN}识别完成

📅 日期：$RECOGNIZED_DATE

🍽️ 食物：
$(echo "$RESULT" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"name"[[:space:]]*:[[:space:]]*"\([^"]*\)"/- \1/g')

数据已保存到健康堡归档。" 2>/dev/null || log "⚠️ 飞书通知发送失败"
        ;;
    
    weight)
        WEIGHT_FILE="daily-output/health/weight-data/${RECOGNIZED_DATE}-weight.md"
        mkdir -p "$(dirname "$WEIGHT_FILE")"
        
        cat > "$WEIGHT_FILE" << EOF
# 体重数据 - $RECOGNIZED_DATE

**数据来源：** 体重秤照片（AI 识别）
**识别时间：** $(date '+%Y-%m-%d %H:%M:%S')

## 数据

| 项目 | 数值 |
|------|------|
| 体重 | $(echo "$RESULT" | grep -o '"weight"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*//') kg |
| 体脂率 | $(echo "$RESULT" | grep -o '"body_fat"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*//')% |
| BMI | $(echo "$RESULT" | grep -o '"bmi"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*//') |

## 原始识别结果

\`\`\`json
$RESULT
\`\`\`
EOF
        log "✅ 体重数据已保存：$WEIGHT_FILE"
        ;;
esac

# 清理临时文件
rm -f "$TEMP_IMAGE"

log "=== 健康数据图片识别完成 ==="
