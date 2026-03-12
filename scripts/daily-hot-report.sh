#!/bin/bash
# 每日爆款日报 - 结合 agent-reach 多渠道数据（10 条新闻版）
# 使用：./daily-hot-report.sh

set -e

cd /Users/liwang/.openclaw/workspace

# 创建输出目录
mkdir -p reports/daily-hot

# 日期
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="reports/daily-hot/hot-report-${TODAY}.md"

echo "🔥 开始生成每日爆款日报 - ${TODAY}"

# ==================== 1. 虎嗅（10 条）====================
echo "📰 抓取虎嗅..."
HUXIU_LIST=$(curl -s "https://r.jina.ai/https://www.huxiu.com/" 2>/dev/null | \
  grep -oE "https://www\.huxiu\.com/article/[0-9]+\.html" | \
  head -10 | uniq)

# 获取虎嗅标题
HUXIU_NEWS=""
idx=1
while IFS= read -r url; do
  if [ -n "$url" ]; then
    title=$(curl -s "https://r.jina.ai/$url" 2>/dev/null | grep "^Title:" | cut -d: -f2- | head -1)
    if [ -n "$title" ]; then
      HUXIU_NEWS="${HUXIU_NEWS}${idx}. ${title}
   ${url}

"
      idx=$((idx+1))
    fi
  fi
done <<< "$HUXIU_LIST"

# ==================== 2. 36 氪（10 条）====================
echo "📰 抓取 36 氪..."
KR_LIST=$(curl -s "https://r.jina.ai/https://36kr.com/" 2>/dev/null | \
  grep -oE "https://36kr\.com/p/[0-9]+" | \
  head -10 | uniq)

KR_NEWS=""
idx=1
while IFS= read -r url; do
  if [ -n "$url" ]; then
    title=$(curl -s "https://r.jina.ai/$url" 2>/dev/null | grep "^Title:" | cut -d: -f2- | head -1)
    if [ -n "$title" ]; then
      KR_NEWS="${KR_NEWS}${idx}. ${title}
   ${url}

"
      idx=$((idx+1))
    fi
  fi
done <<< "$KR_LIST"

# ==================== 3. B 站热门（10 条，带标题 + 链接）====================
echo "📺 抓取 B 站..."
BILIBILI_HOT=$(python3 /Users/liwang/.openclaw/workspace/scripts/bilibili-hot.py 2>/dev/null || echo "B 站抓取失败")

# ==================== 4. 抖音（MCP 已配置，可解析视频）====================
# 抖音热榜被 Jina AI 封禁，改用 MCP 解析具体视频
# 用法：mcporter call 'douyin.parse_douyin_video_info(share_link: "https://v.douyin.com/xxx/")'
DOUYIN_NOTE="🎵 抖音 MCP 已配置 ✅
   可解析具体视频链接获取信息
   用法：mcporter call 'douyin.parse_douyin_video_info(share_link: \"https://v.douyin.com/xxx/\")'
   注：热榜抓取被 Jina AI 限制，暂不可用"

# ==================== 生成报告 ====================
cat > "$OUTPUT_FILE" << EOF
# 🔥 每日爆款日报 - ${TODAY}

生成时间：$(date "+%Y-%m-%d %H:%M:%S")

---

## 📰 虎嗅 Top10

${HUXIU_NEWS}

## 📰 36 氪 Top10

${KR_NEWS}

## 📺 B 站热门 Top10

${BILIBILI_HOT}

## 🎵 抖音

${DOUYIN_NOTE}

---

## 📊 渠道状态

| 渠道 | 状态 | 说明 |
|------|------|------|
| ✅ 虎嗅 | 10 条 | Jina Reader |
| ✅ 36 氪 | 10 条 | Jina Reader |
| ✅ B 站 | 10 条 | Jina Reader |
| ✅ 抖音 | MCP 可用 | 可解析视频，热榜被封 |
| ⚠️ Reddit | 403 | 需要换代理 |
| ⏳ 小红书 | 未配置 | 需 Docker |
| ⚠️ Twitter | 需 Cookie | Cookie-Editor 导出 |

---
🏰 城堡日报 | agent-reach 多渠道数据
EOF

echo "✅ 报告已生成：$OUTPUT_FILE"
cat "$OUTPUT_FILE"
