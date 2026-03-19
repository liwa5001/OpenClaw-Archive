#!/bin/bash

# 有声读本每日生成脚本
# 用法：./generate-audiobook-day.sh <day_number>

DAY=$1
WORKSPACE="/Users/liwang/.openclaw/workspace"
AUDIO_DIR="$WORKSPACE/audiobook/audio"
LOG_FILE="$WORKSPACE/logs/audiobook-generation.log"

# 章节内容映射
declare -A CHAPTERS
CHAPTERS[1]="第 1 章 序言。人生百态，各有千秋。一个人生活在这个世界上，就要面对各种各样的人、各种各样的事、各种各样的人际关系。一个人不管有多聪明，多能干，背景条件有多好，如果不懂得如何做人、做事，那么他最终的结局肯定是失败。怎样去修炼为人处世的道行呢？古人说：天地间真滋味，唯静者能尝得出。在你无法改变一些人和事的时候，就需要改变自己，努力让自己适应这个社会。如果不想处处碰壁，你就必须懂得一些人情世故，掌握一些交际礼仪和沟通技巧，灵活地处世。"

CHAPTERS[2]="第 2 章到第 4 章，大智若愚，智慧的最高境界，上集。真正聪明的人，往往看起来都很笨拙。这不是伪装，而是一种境界。老子说：大智若愚，大巧若拙。在职场中，那些锋芒毕露的人，往往最先被淘汰。而真正有智慧的人，懂得收敛光芒，在关键时刻才展现自己的实力。记住，木秀于林，风必摧之。学会低调，是一种保护色。"

# 更多章节内容...

if [ -z "$DAY" ]; then
    echo "用法：$0 <day_number>"
    echo "示例：$0 1"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始生成第$DAY天音频" >> "$LOG_FILE"

# 获取章节文本
TEXT="${CHAPTERS[$DAY]}"

if [ -z "$TEXT" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：第$DAY天内容不存在" >> "$LOG_FILE"
    exit 1
fi

# 生成 TTS 音频（使用 Edge TTS，女生声音）
OUTPUT_FILE="$AUDIO_DIR/day$(printf "%02d" $DAY).mp3"

edge-tts --voice zh-CN-XiaoxiaoNeural --text "$TEXT" --write-media "$OUTPUT_FILE" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 第$DAY天音频生成成功：$OUTPUT_FILE" >> "$LOG_FILE"
    echo "✅ 音频已生成：$OUTPUT_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 第$DAY天音频生成失败" >> "$LOG_FILE"
    echo "❌ 音频生成失败，请检查日志：$LOG_FILE"
    exit 1
fi
