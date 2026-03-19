#!/bin/bash
# 成长堡每日复盘脚本 - 每天晚上 21:00 发送

# Cleanup 机制
cleanup() {
  local exit_code=$?
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 清理临时资源..." >> logs/growth-daily-review.log
  rm -f /tmp/growth_*.tmp 2>/dev/null || true
  [ $exit_code -eq 0 ] && echo "✅ 成长堡复盘完成" >> logs/growth-daily-review.log || echo "❌ 成长堡复盘失败 ($exit_code)" >> logs/growth-daily-review.log
  exit $exit_code
}
# 超时设置
TIMEOUT_SECONDS=90

trap cleanup EXIT INT TERM

set -e

cd /Users/liwang/.openclaw/workspace
mkdir -p logs

DATE=$(date +%Y-%m-%d)
START_DATE="2026-03-09"

# 计算第几周第几天
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s)
TODAY_TS=$(date -j -f "%Y-%m-%d" "$DATE" +%s)
DAYS_ELAPSED=$(( (TODAY_TS - START_TS) / 86400 + 1 ))
WEEK_NUM=$(( (DAYS_ELAPSED - 1) / 7 + 1 ))
DAY_IN_WEEK=$(( (DAYS_ELAPSED - 1) % 7 + 1 ))

echo "========================================" >> logs/growth-daily-review.log
echo "📚 成长堡每日复盘 | $DATE" >> logs/growth-daily-review.log
echo "第 $WEEK_NUM 周 第 $DAY_IN_WEEK 天" >> logs/growth-daily-review.log

# 获取本机 IP
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

# 检查并启动成长堡服务器
if ! curl -s "http://localhost:8896" > /dev/null 2>&1; then
    echo "🚀 启动成长堡服务器..."
    cd /Users/liwang/.openclaw/workspace/growth-form
    nohup node server.js > /Users/liwang/.openclaw/workspace/logs/growth-server.log 2>&1 &
    sleep 2
    echo "✅ 成长堡服务器已启动"
else
    echo "✅ 成长堡服务器已运行"
fi

# 发送复盘问卷到飞书（含 HTML 表单链接）
# 飞书 Markdown 链接格式：[文本](URL)
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "📚 成长堡每日复盘 | $DATE

花 2 分钟填写今天的学习情况~

👉 点击填写表单：[http://${LOCAL_IP}:8896/](http://${LOCAL_IP}:8896/)

【填写内容】
📖 今日学习（OpenClaw/Claude AI/视频制作）
⭐ 学习质量自评（1-5 分）
📝 今日产出（笔记/实操/作品）
💡 遇到的问题
📅 明日计划调整

【12 周计划进度】
第 $WEEK_NUM 周 第 $DAY_IN_WEEK 天

提交后立即收到评分和建议！🚀

---
🏰 城堡成长堡 | 持续学习，每天进步！
"

echo "✅ 复盘问卷已发送（飞书） - $(date)"
