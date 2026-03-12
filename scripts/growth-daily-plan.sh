#!/bin/bash
# 成长堡每日学习计划提醒脚本
# 每天早上 8:00 发送：成长问卷 + 学习计划 + 考题

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/growth-daily-plan.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 成长堡每日学习计划发送开始 ==="

# 获取本机 IP
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

TODAY=$(date '+%Y-%m-%d')

# 计算 12 周计划进度
START_DATE="2026-03-10"
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s 2>/dev/null || echo "1773091200")
NOW_TS=$(date +%s)
DAYS_ELAPSED=$(( (NOW_TS - START_TS) / 86400 ))
WEEK_NUM=$(( DAYS_ELAPSED / 7 + 1 ))
DAY_NUM=$(( DAYS_ELAPSED % 7 + 1 ))

# 根据周数获取当天学习计划
get_daily_plan() {
    local week=$1
    local day=$2
    
    if [ "$week" -eq 1 ]; then
        case "$day" in
            1) echo "OpenClaw 架构认知|OC-01|BV1jEAaz3E6K|10min|60min|理解整体架构" ;;
            2) echo "OpenClaw 安装配置|OC-02|BV1TpAZzeEiZ|前 25min|90min|完成安装" ;;
            3) echo "OpenClaw 深入实践|OC-02|BV1TpAZzeEiZ|后 28min|60min|配置 Skills" ;;
            4) echo "Skill 开发基础|OC-03|BV1G3FNznEiS|前 10min|90min|理解原理" ;;
            5) echo "Skill 实战练习|OC-03|BV1G3FNznEiS|后 9min|60min|编写 1 个 Skill" ;;
            6) echo "健康堡 MVP 开发|实践|无视频|90min|MVP 原型" ;;
            7) echo "W1 复习 + 测试|综合复习|60min|测试报告|通过率 85%" ;;
        esac
    elif [ "$week" -eq 2 ]; then
        case "$day" in
            1) echo "Claude 基础使用|CA-06|12:44|60min|3 个应用场景" ;;
            2) echo "AI 习惯养成|CA-07|10:50|60min|3 个习惯实践" ;;
            3) echo "AI 原生思维|CA-08|8:55|60min|思维转变" ;;
            4) echo "Prompt 工程基础|CA-04|8:30|90min|Prompt 公式" ;;
            5) echo "ChatGPT 进阶|CA-05|8:45|60min|10 个技巧" ;;
            6) echo "Claude Code 入门|CA-02|前 20min|90min|1 个脚本" ;;
            7) echo "W2 复习 + 测试|综合复习|60min|测试报告|通过率 85%" ;;
        esac
    else
        echo "复习/自由学习|自主安排|自主安排|90min|本周总结|完成总结"
    fi
}

PLAN_INFO=$(get_daily_plan $WEEK_NUM $DAY_NUM)
IFS='|' read -r TOPIC VIDEO_ID BV_ID DURATION TARGET GOAL <<< "$PLAN_INFO"

# 生成视频链接
if [ "$BV_ID" != "无视频" ] && [ -n "$BV_ID" ]; then
    VIDEO_URL="https://www.bilibili.com/video/$BV_ID"
    VIDEO_TEXT="🎥 **视频链接：**
$VIDEO_URL

⏱️ **观看要求：** $DURATION"
else
    VIDEO_TEXT="📚 **今日为实践日，无视频内容**"
fi

# 检查并启动服务器
if ! curl -s "http://localhost:8896" > /dev/null 2>&1; then
    log "启动成长堡服务器..."
    cd "$WORKSPACE/growth-form"
    nohup node server.js > "$WORKSPACE/logs/growth-server.log" 2>&1 &
    sleep 2
    log "✅ 成长堡服务器已启动"
else
    log "成长堡服务器已运行"
fi

if ! curl -s "http://localhost:8898" > /dev/null 2>&1; then
    log "启动考题服务器..."
    cd "$WORKSPACE/quiz-form"
    nohup node server.js > "$WORKSPACE/logs/quiz-server.log" 2>&1 &
    sleep 2
    log "✅ 考题服务器已启动"
else
    log "考题服务器已运行"
fi

# 发送飞书消息
log "发送成长堡学习计划..."

MESSAGE="📚 **成长堡每日学习计划提醒 | $TODAY**

**12 周计划：** 第${WEEK_NUM}周 第${DAY_NUM}天

━━━━━━━━━━━━━━━━━━

📝 **成长堡每日复盘**

花 3 分钟回顾学习成长~

👉 http://${LOCAL_IP}:8896/

【填写内容】
📖 今日学习 | ⭐ 质量自评 | 📝 今日产出
📝 每日题目 | 🎥 视频链接 | 📋 考题记录

━━━━━━━━━━━━━━━━━━

📖 **今日学习任务**

**主题：** $TOPIC
**目标：** $GOAL
**时长：** ${TARGET}

$VIDEO_TEXT

━━━━━━━━━━━━━━━━━━

📝 **每日考题**

完成学习后，点击链接答题：

👉 http://${LOCAL_IP}:8898/

（HTML 表单，答案直接记录到学习档案）

━━━━━━━━━━━━━━━━━━

💡 **建议流程：**
1️⃣ 填写成长堡复盘（3 分钟）
2️⃣ 观看视频学习（$DURATION）
3️⃣ 完成实践任务
4️⃣ 答题巩固（HTML 表单）

---
🏰 城堡成长堡 | 持续学习，日拱一卒！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"
log "✅ 成长堡学习计划已发送"
log "=== 成长堡每日学习计划发送完成 ==="
