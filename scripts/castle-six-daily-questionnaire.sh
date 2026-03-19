#!/bin/bash
# Castle Six 每日问卷 + 学习计划发送脚本（统一版）
# 每天早上 8:00 发送：健康堡表单 + 成长堡表单 + 学习计划 + 考题

# Cleanup 机制
cleanup() {
  local exit_code=$?
  log "清理临时资源..."
  rm -f /tmp/castle_*.tmp 2>/dev/null || true
  # 停止后台服务器（如果是本脚本启动的）
  [ -n "$SERVER_PID" ] && kill $SERVER_PID 2>/dev/null || true
  [ $exit_code -eq 0 ] && log "✅ Castle Six 发送完成" || log "❌ 失败 ($exit_code)"
  exit $exit_code
}
trap cleanup EXIT INT TERM

# 超时设置
TIMEOUT_SECONDS=120

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
mkdir -p "$WORKSPACE/logs"
LOG_FILE="$WORKSPACE/logs/castle-six-sender.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "=== Castle Six 问卷 + 学习计划发送开始 (超时：${TIMEOUT_SECONDS}秒) ==="

# 获取本机 IP（macOS 兼容）
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

TODAY=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=周一，7=周日

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

# 启动健康堡服务器
if ! curl -s "http://localhost:8897" > /dev/null 2>&1; then
    log "启动健康堡服务器 (8897)..."
    cd "$WORKSPACE/health-form"
    nohup node server.js > "$WORKSPACE/logs/health-server.log" 2>&1 &
    sleep 2
    log "✅ 健康堡服务器已启动"
else
    log "健康堡服务器已运行"
fi

# 启动成长堡服务器
if ! curl -s "http://localhost:8896" > /dev/null 2>&1; then
    log "启动成长堡服务器 (8896)..."
    cd "$WORKSPACE/growth-form"
    nohup node server.js > "$WORKSPACE/logs/growth-server.log" 2>&1 &
    sleep 2
    log "✅ 成长堡服务器已启动"
else
    log "成长堡服务器已运行"
fi

# 生成链接
HEALTH_URL="http://${LOCAL_IP}:8897/"
GROWTH_URL="http://${LOCAL_IP}:8896/"

# 根据星期几生成体重提示
if [ "$WEEKDAY" -eq 1 ]; then
    WEIGHT_NOTE="⚖️ 体重记录：今天是周一，记得填写体重"
else
    WEIGHT_NOTE="⚖️ 体重记录：仅周一填写"
fi

# 发送消息 1：健康堡问卷（单独）
log "发送健康堡问卷..."

MESSAGE1="💪 **健康堡每日问卷 | $TODAY**

花 2 分钟填写健康数据~

👉 http://${LOCAL_IP}:8897/

【填写内容】
🏃 运动训练 | 🍽️ 饮食记录 | 😴 睡眠质量
$WEIGHT_NOTE

【自动同步】
📊 Strava 运动数据：已加载

提交后立即收到评分和建议！🚀

---
🏰 城堡健康堡 | 科学训练，持续进步！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE1"
log "✅ 健康堡问卷已发送"

# 发送消息 2：成长堡问卷 + 学习计划（合并）
log "发送成长堡每日学习计划提醒..."

MESSAGE2="📚 **成长堡每日学习计划提醒 | $TODAY**

**12 周计划：** 第${WEEK_NUM}周 第${DAY_NUM}天

━━━━━━━━━━━━━━━━━━

📝 **成长堡每日复盘**

花 3 分钟回顾学习成长~

👉 $GROWTH_URL

【填写内容】
📖 今日学习 | ⭐ 质量自评 | 📝 今日产出
💡 问题与明日计划

━━━━━━━━━━━━━━━━━━

📖 **今日学习任务**

**主题：** $TOPIC
**目标：** $GOAL
**时长：** ${TARGET}

$VIDEO_TEXT

━━━━━━━━━━━━━━━━━━

💡 **建议流程：**
1️⃣ 填写成长堡复盘（3 分钟）
2️⃣ 观看视频学习（$DURATION）
3️⃣ 完成实践任务

---
🏰 城堡成长堡 | 持续学习，日拱一卒！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE2"
log "✅ 成长堡每日学习计划提醒已发送"

# 发送消息 3：每日考题（独立）
log "发送每日考题 HTML 表单..."

MESSAGE3="📝 **每日考题 | 第${WEEK_NUM}周 第${DAY_NUM}天**

完成学习后，点击链接答题：

👉 $QUIZ_URL

【考题说明】
- 📚 每日 4 道选择题
- ✅ 自动评分，记录到学习档案
- 💡 巩固当日学习内容

提交后查看分数和解析！🎯

---
🏰 城堡成长堡 | 每日进步一点点！
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE3"
log "✅ 每日考题已发送"

log "=== Castle Six 每日任务发送完成 ==="
log "🎉 健康堡问卷 + 成长堡学习计划 + 每日考题已发送"

exit 0
