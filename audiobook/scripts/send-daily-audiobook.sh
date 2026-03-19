#!/bin/bash

# 有声读本每日推送脚本
# 发送到成长堡飞书消息

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/audiobook-sender.log"
PUBLIC_URL_FILE="$WORKSPACE/logs/audiobook-public-url.txt"

# 获取公网 URL
PUBLIC_URL=$(cat "$PUBLIC_URL_FILE" 2>/dev/null)

if [ -z "$PUBLIC_URL" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 未找到公网 URL" >> "$LOG_FILE"
    exit 1
fi

# 获取当前天数（从进度文件）
PROGRESS_FILE="$WORKSPACE/audiobook/progress/user-progress.json"
if [ -f "$PROGRESS_FILE" ]; then
    CURRENT_DAY=$(cat "$PROGRESS_FILE" | grep -o '"currentDay":[0-9]*' | cut -d':' -f2)
else
    CURRENT_DAY=1
fi

# 章节标题
CHAPTERS=(
    "第 1 章 序言"
    "第 2-4 章 大智若愚 (上)"
    "第 2-4 章 大智若愚 (下)"
    "第 5-8 章 吃亏是福 (上)"
    "第 5-8 章 吃亏是福 (下)"
    "第 9-11 章 谦虚忍耐"
    "第 12-14 章 宽容大度 (上)"
    "第 12-14 章 宽容大度 (下)"
    "第 15-18 章 管住舌头 (上)"
    "第 15-18 章 管住舌头 (下)"
    "第 19-21 章 韬光养晦"
    "第 22-27 章 方圆哲学 + 知足常乐"
    "第 28-39 章 人情往来 + 感恩有爱"
)

CHAPTER_TITLE="${CHAPTERS[$CURRENT_DAY-1]}"

# 发送飞书消息
MESSAGE="📚 **有声读本 - 第$CURRENT_DAY 天**

📖 今日内容：$CHAPTER_TITLE

🎧 👉 **点击收听：[$PUBLIC_URL]($PUBLIC_URL)**

---
💡 功能说明：
- ✅ 自动记录播放进度
- ✅ 下次继续播放
- ✅ 支持 0.75x-1.5x 语速
- ✅ 手机/电脑都能用

📊 进度已自动同步到成长堡
"

# 使用 openclaw message 发送
cd "$WORKSPACE"
openclaw message send --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 已发送第$CURRENT_DAY 天有声读本链接" >> "$LOG_FILE"
