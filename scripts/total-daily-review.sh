#!/bin/bash
# Castle Six 总复盘堡脚本
# 每天晚上 21:30 发送，综合健康堡 + 成长堡数据

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/total-review.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Castle Six 总复盘开始 ==="

TODAY=$(date '+%Y-%m-%d')
YESTERDAY=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')

# 读取健康堡数据
HEALTH_FILE="$WORKSPACE/daily-output/health/daily-stats/$TODAY-health-stats.md"
if [ -f "$HEALTH_FILE" ]; then
    HEALTH_SCORE=$(grep "综合评分" "$HEALTH_FILE" | head -1 | grep -o "[0-9]*/100" || echo "待评估")
    EXERCISE=$(grep "训练状态" "$HEALTH_FILE" | head -1 || echo "待记录")
    SLEEP=$(grep "睡眠时长" "$HEALTH_FILE" | head -1 || echo "待记录")
else
    HEALTH_SCORE="未填写"
    EXERCISE="待记录"
    SLEEP="待记录"
fi

# 读取成长堡数据
GROWTH_FILE="$WORKSPACE/daily-output/growth/daily-stats/$TODAY-growth-stats.md"
if [ -f "$GROWTH_FILE" ]; then
    GROWTH_SCORE=$(grep "综合评分" "$GROWTH_FILE" | head -1 | grep -o "[0-9]*/100" || echo "待评估")
    STUDY_TIME=$(grep "总计" "$GROWTH_FILE" | head -1 || echo "待记录")
    QUALITY=$(grep "质量评分" "$GROWTH_FILE" | head -1 || echo "待记录")
else
    GROWTH_SCORE="未填写"
    STUDY_TIME="待记录"
    QUALITY="待记录"
fi

# 生成总评
if [[ "$HEALTH_SCORE" =~ ^[0-9]+ ]] && [[ "$GROWTH_SCORE" =~ ^[0-9]+ ]]; then
    HEALTH_NUM=$(echo "$HEALTH_SCORE" | grep -o "[0-9]*")
    GROWTH_NUM=$(echo "$GROWTH_SCORE" | grep -o "[0-9]*")
    TOTAL_SCORE=$(( (HEALTH_NUM + GROWTH_NUM) / 2 ))
    
    if [ $TOTAL_SCORE -ge 85 ]; then
        TOTAL_TEXT="优秀🌟 双堡表现都很出色！"
    elif [ $TOTAL_SCORE -ge 70 ]; then
        TOTAL_TEXT="良好✅ 继续保持！"
    elif [ $TOTAL_SCORE -ge 60 ]; then
        TOTAL_TEXT="及格👌 还有提升空间"
    else
        TOTAL_TEXT="加油💪 明天会更好！"
    fi
else
    TOTAL_SCORE="待评估"
    TOTAL_TEXT="请先填写健康堡和成长堡"
fi

# 发送飞书消息
log "发送总复盘..."

MESSAGE="🏰 **Castle Six 总复盘 | $TODAY**

━━━━━━━━━━━━━━━━━━

## 📊 今日总评

**综合评分：** ${TOTAL_SCORE}/100
**评估：** $TOTAL_TEXT

━━━━━━━━━━━━━━━━━━

## 💪 健康堡

**评分：** $HEALTH_SCORE
**运动：** $EXERCISE
**睡眠：** $SLEEP

━━━━━━━━━━━━━━━━━━

## 📚 成长堡

**评分：** $GROWTH_SCORE
**学习：** $STUDY_TIME
**质量：** $QUALITY

━━━━━━━━━━━━━━━━━━

## 💡 明日建议

🏃 **健康方面：**
- 保持运动习惯
- 优化睡眠质量

📚 **学习方面：**
- 完成明日学习计划
- 坚持答题巩固

🏰 **总复盘堡：**
- 双堡数据持续积累
- 周末进行深度分析

━━━━━━━━━━━━━━━━━━

📈 **数据追踪：**
- 健康堡数据：\`daily-output/health/daily-stats/\`
- 成长堡数据：\`daily-output/growth/daily-stats/\`
- 考题答案：\`daily-output/growth/quiz-answers/\`

---
🏰 城堡六堡 | 全面复盘，持续进步！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"
log "✅ Castle Six 总复盘已发送"
log "=== Castle Six 总复盘完成 ==="
