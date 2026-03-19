#!/bin/bash

# 听书记录同步到成长堡数据
# 在用户提交每日复盘时调用

WORKSPACE="/Users/liwang/.openclaw/workspace"
DATE=$1
AUDIOBOOK_DAY=$2
REFLECTION=$3
RATING=$4

OUTPUT_DIR="$WORKSPACE/daily-output/growth/audiobook-reflections"

# 确保目录存在
mkdir -p "$OUTPUT_DIR"

if [ -z "$DATE" ] || [ -z "$AUDIOBOOK_DAY" ]; then
    echo "用法：$0 <date> <audiobook_day> [reflection] [rating]"
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/$DATE-audiobook-reflection.md"

cat > "$OUTPUT_FILE" << EOF
# 🎧 听书记录 - $DATE

**书籍：** 《每天懂点人情世故》  
**听到：** 第 $AUDIOBOOK_DAY 天  
**评分：** ${RATING:-未评分}/5 ⭐

---

## 💭 今日感想

$REFLECTION

---

## 📝 城堡备注

- 记录时间：$(date '+%Y-%m-%d %H:%M:%S')
- 数据来源：成长堡每日复盘表单

EOF

echo "✅ 听书记录已保存：$OUTPUT_FILE"
