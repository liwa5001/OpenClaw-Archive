#!/bin/bash
# 合并晨报和爆款日报生成 MP3 文件（纯中文版）
# 保存到：/workspace/audio/daily-YYYY-MM-DD.mp3
# 使用：./scripts/merge-daily-audio.sh

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace
mkdir -p logs audio

echo "🎙️ 开始生成合并版音频（纯中文）- $(date '+%Y-%m-%d %H:%M:%S')" >> logs/merged-audio.log

# ==================== 1. 获取今天的日期 ====================
TODAY=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(date +%-m)
DAY=$(date +%-d)
WEEKDAY=$(date +%u)

# 星期转换
case $WEEKDAY in
  1) WEEKDAY_CN="星期一" ;;
  2) WEEKDAY_CN="星期二" ;;
  3) WEEKDAY_CN="星期三" ;;
  4) WEEKDAY_CN="星期四" ;;
  5) WEEKDAY_CN="星期五" ;;
  6) WEEKDAY_CN="星期六" ;;
  7) WEEKDAY_CN="星期日" ;;
esac

# ==================== 2. 生成纯中文朗读文本 ====================
echo "📝 生成纯中文朗读文本..." >> logs/merged-audio.log

# 创建临时文件
TTS_FILE="/tmp/tts-cn-text-${TODAY}.txt"
> "$TTS_FILE"

# 开场白
echo "早上好，今天是${YEAR}年${MONTH}月${DAY}日，${WEEKDAY_CN}。欢迎收听今日新闻和爆款日报。" >> "$TTS_FILE"
echo "" >> "$TTS_FILE"

# 从晨报文件提取内容
MORNING_NEWS_FILE="/Users/liwang/.openclaw/workspace/memory/${TODAY}.md"
HOT_REPORT_FILE="/Users/liwang/.openclaw/workspace/reports/daily-hot/hot-report-ultimate-${TODAY}.md"

echo "首先是新闻部分。" >> "$TTS_FILE"
echo "" >> "$TTS_FILE"

if [ -f "$MORNING_NEWS_FILE" ]; then
  # 提取国际新闻（从"### 🌍 国际新闻"到下一个"###"或空行）
  echo "国际新闻：" >> "$TTS_FILE"
  sed -n '/### 🌍 国际新闻/,/^### /p' "$MORNING_NEWS_FILE" | grep "^[0-9]\." | head -3 | sed 's/^[0-9]*\. //' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
  
  # 提取国内新闻
  echo "国内新闻：" >> "$TTS_FILE"
  sed -n '/### 🇨🇳 国内新闻/,/^### /p' "$MORNING_NEWS_FILE" | grep "^[0-9]\." | head -3 | sed 's/^[0-9]*\. //' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
  
  # 提取 AI 新闻
  echo "人工智能领域：" >> "$TTS_FILE"
  sed -n '/### 🤖 AI 新闻/,/^### /p' "$MORNING_NEWS_FILE" | grep "^[0-9]\." | head -3 | sed 's/^[0-9]*\. //' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
  
  # 提取汽车新闻
  echo "汽车新闻：" >> "$TTS_FILE"
  sed -n '/### 🚗 汽车新闻/,/^### /p' "$MORNING_NEWS_FILE" | grep "^[0-9]\." | head -3 | sed 's/^[0-9]*\. //' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
fi

# 提取爆款日报内容
echo "接下来是爆款日报。" >> "$TTS_FILE"
echo "" >> "$TTS_FILE"

if [ -f "$HOT_REPORT_FILE" ]; then
  # 提取虎嗅（前 3 条）
  echo "虎嗅热门：" >> "$TTS_FILE"
  sed -n '/### 虎嗅 Top10/,/^### /p' "$HOT_REPORT_FILE" | grep "^[[:space:]]*[0-9]\." | head -3 | sed 's/^[[:space:]]*[0-9]*\. //' | sed 's/^ *//' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
  
  # 提取 36 氪（前 3 条）
  echo "三六氪热门：" >> "$TTS_FILE"
  sed -n '/### 36 氪 Top10/,/^### /p' "$HOT_REPORT_FILE" | grep "^[[:space:]]*[0-9]\." | head -3 | sed 's/^[[:space:]]*[0-9]*\. //' | sed 's/^ *//' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
  
  # 提取 B 站（前 2 条）
  echo "哔哩哔哩热门：" >> "$TTS_FILE"
  sed -n '/### B 站热门 Top10/,/^### /p' "$HOT_REPORT_FILE" | grep "^[[:space:]]*[0-9]\." | head -2 | sed 's/^[[:space:]]*[0-9]*\. //' | sed 's/^ *//' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
  
  # 提取 GitHub（前 3 条）
  echo "吉特哈布热门：" >> "$TTS_FILE"
  sed -n '/### GitHub Trending Top10/,/^###\|^---/p' "$HOT_REPORT_FILE" | grep "^[[:space:]]*[0-9]\." | head -3 | sed 's/^[[:space:]]*[0-9]*\. //' | sed 's/^ *//' >> "$TTS_FILE"
  echo "" >> "$TTS_FILE"
fi

# 结束语
echo "以上是今天的晨报和爆款日报全部内容。感谢收听，祝你有收获满满的一天！" >> "$TTS_FILE"

LINE_COUNT=$(wc -l < "$TTS_FILE")
echo "✅ 纯中文文本已生成，共 ${LINE_COUNT} 行" >> logs/merged-audio.log

# ==================== 3. 使用 macOS say 生成音频 ====================
echo "🔊 使用 macOS say 生成音频..." >> logs/merged-audio.log

# 生成 AIFF 格式
say -v Mei-Jia -r 170 < "$TTS_FILE" -o /tmp/merged-cn.aiff 2>/dev/null

# 转换为 MP3（32kbps，小文件）
ffmpeg -i /tmp/merged-cn.aiff -codec:a libmp3lame -b:a 32k -ar 16000 -ac 1 /Users/liwang/.openclaw/workspace/audio/daily-${TODAY}.mp3 -y 2>/dev/null

# 检查音频文件
OUTPUT_FILE="/Users/liwang/.openclaw/workspace/audio/daily-${TODAY}.mp3"
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
  DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_FILE" 2>/dev/null | cut -d. -f1)
  echo "✅ 合并音频已生成：$OUTPUT_FILE ($FILE_SIZE, ${DURATION}秒)" >> logs/merged-audio.log
  
  # ==================== 4. 发送到飞书（文字稿）====================
  echo "📤 发送文字稿到飞书..." >> logs/merged-audio.log
  
  /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🎧 每日合并朗读版（文字稿）- ${TODAY}

纯中文朗读稿已生成，内容包含：
- 📰 国际/国内/AI/汽车新闻
- 🔥 虎嗅/36 氪/B 站/GitHub

⏱️ 音频时长：约 $((DURATION / 60)) 分钟
📁 音频文件：/workspace/audio/daily-${TODAY}.mp3
📦 文件大小：${FILE_SIZE}

💡 使用方法：
1. 复制上方文字到 iPhone 备忘录
2. 全选 → 点击"朗读"
或
1. 打开电脑音频文件夹
2. 播放 MP3 文件
3. AirDrop 传到手机收听

🏰 城堡日报 | 纯中文朗读稿" 2>/dev/null
  
  echo "✅ 文字稿发送完成 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/merged-audio.log
  
  # 清理临时文件
  rm -f /tmp/merged-cn.aiff "$TTS_FILE"
  echo "✅ 合并音频任务完成 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/merged-audio.log
else
  echo "❌ TTS 音频生成失败" >> logs/merged-audio.log
  exit 1
fi
