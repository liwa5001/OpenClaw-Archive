#!/bin/bash
# 每日爆款日报 - 带概要和链接的测试版

set -e
cd /Users/liwang/.openclaw/workspace
mkdir -p reports/daily-hot

TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="reports/daily-hot/hot-report-test-${TODAY}.md"

echo "🔥 生成带概要的日报测试版 - ${TODAY}"

# ==================== 1. 虎嗅（5 条带概要）====================
echo "📰 抓取虎嗅..."
HUXIU_URLS=$(curl -s "https://r.jina.ai/https://www.huxiu.com/" 2>/dev/null | \
  grep -oE "https://www\.huxiu\.com/article/[0-9]+\.html" | head -5 | uniq)

HUXIU_CONTENT=""
idx=1
while IFS= read -r url; do
  if [ -n "$url" ]; then
    content=$(curl -s "https://r.jina.ai/$url" 2>/dev/null)
    title=$(echo "$content" | grep "^Title:" | cut -d: -f2- | head -1)
    # 提取前 200 字作为概要
    summary=$(echo "$content" | sed -n '/^Title:/,/^-/p' | tail -n +2 | head -10 | tr '\n' ' ' | cut -c1-200)
    if [ -n "$title" ]; then
      HUXIU_CONTENT="${HUXIU_CONTENT}**${idx}. ${title}**
${summary}...
🔗 [阅读全文](${url})

"
      idx=$((idx+1))
    fi
  fi
done <<< "$HUXIU_URLS"

# ==================== 2. 36 氪（5 条带概要）====================
echo "📰 抓取 36 氪..."
KR_URLS=$(curl -s "https://r.jina.ai/https://36kr.com/" 2>/dev/null | \
  grep -oE "https://36kr\.com/p/[0-9]+" | head -5 | uniq)

KR_CONTENT=""
idx=1
while IFS= read -r url; do
  if [ -n "$url" ]; then
    content=$(curl -s "https://r.jina.ai/$url" 2>/dev/null)
    title=$(echo "$content" | grep "^Title:" | cut -d: -f2- | head -1)
    summary=$(echo "$content" | sed -n '/^Title:/,/^-/p' | tail -n +2 | head -10 | tr '\n' ' ' | cut -c1-200)
    if [ -n "$title" ]; then
      KR_CONTENT="${KR_CONTENT}**${idx}. ${title}**
${summary}...
🔗 [阅读全文](${url})

"
      idx=$((idx+1))
    fi
  fi
done <<< "$KR_URLS"

# ==================== 3. B 站（5 条）====================
echo "📺 抓取 B 站..."
BILIBILI_CONTENT=$(curl -s "https://r.jina.ai/https://www.bilibili.com/v/popular/ranking/all" 2>/dev/null | \
  grep -oE "https://www\.bilibili\.com/video/BV[a-zA-Z0-9]+" | head -5 | \
  awk '{print NR". 🔗 [观看视频]("$0")"}' 2>/dev/null)

# ==================== 生成报告 ====================
cat > "$OUTPUT_FILE" << EOF
# 🔥 每日爆款日报 - 带概要测试版 | ${TODAY}

生成时间：$(date "+%Y-%m-%d %H:%M:%S")

---

## 📰 虎嗅 Top5

${HUXIU_CONTENT}

## 📰 36 氪 Top5

${KR_CONTENT}

## 📺 B 站热门 Top5

${BILIBILI_CONTENT}

---
🏰 城堡日报 | 每条新闻都有概要 + 链接
EOF

echo "✅ 报告已生成：$OUTPUT_FILE"
cat "$OUTPUT_FILE"
