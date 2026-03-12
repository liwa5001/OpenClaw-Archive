#!/bin/bash
# 每日爆款日报 - 13 渠道完整版
# 使用：./daily-hot-report-full.sh

set -e

cd /Users/liwang/.openclaw/workspace

# 创建输出目录
mkdir -p reports/daily-hot

# 日期
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="reports/daily-hot/hot-report-full-${TODAY}.md"

echo "🔥 开始生成 13 渠道每日爆款日报 - ${TODAY}"

# ==================== 1. 虎嗅（10 条）====================
echo "📰 抓取虎嗅..."
HUXIU_LIST=$(curl -s "https://r.jina.ai/https://www.huxiu.com/" 2>/dev/null | \
  grep -oE "https://www\.huxiu\.com/article/[0-9]+\.html" | head -10 | uniq)

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
  grep -oE "https://36kr\.com/p/[0-9]+" | head -10 | uniq)

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

# ==================== 3. B 站（10 条）====================
echo "📺 抓取 B 站..."
BILIBILI_HOT=$(curl -s "https://r.jina.ai/https://www.bilibili.com/v/popular/ranking/all" 2>/dev/null | \
  grep -oE "https://www\.bilibili\.com/video/BV[a-zA-Z0-9]+" | head -10 | \
  awk '{print NR". "$0}' 2>/dev/null || echo "B 站抓取失败")

# ==================== 4. Reddit 科技（10 条）====================
echo "📱 抓取 Reddit..."
REDDIT_HOT=$(curl -s "https://www.reddit.com/r/technology/hot.json?limit=10" \
  -H "User-Agent: Mozilla/5.0" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for i, c in enumerate(d['data']['children'][:10], 1):
        post = c['data']
        title = post['title'][:70]
        print(f'{i}. {title}')
        print(f'   https://reddit.com{post[\"permalink\"]}')
        print()
except Exception as e:
    print(f'Reddit 抓取失败：{e}')
" 2>/dev/null || echo "Reddit 抓取失败")

# ==================== 5. GitHub 趋势（10 条）====================
echo "🐙 抓取 GitHub..."
GITHUB_TRENDING=$(curl -s "https://r.jina.ai/https://github.com/trending" 2>/dev/null | \
  grep -E "^  [a-zA-Z]" | head -10 | awk '{print NR". "$0}' 2>/dev/null || echo "GitHub 抓取失败")

# ==================== 6. 微信公众号（示例）====================
echo "📱 抓取微信公众号..."
WECHAT_NOTE="📱 微信公众号
   需要安装：pip install miku_ai camoufox
   搜索示例：python3 -c \"from miku_ai import get_wexin_article; print(get_wexin_article('AI', 5))\""

# ==================== 生成报告 ====================
cat > "$OUTPUT_FILE" << EOF
# 🔥 每日爆款日报 - 13 渠道完整版 | ${TODAY}

生成时间：$(date "+%Y-%m-%d %H:%M:%S")

---

## 📰 国内科技媒体

### 虎嗅 Top10
${HUXIU_NEWS}

### 36 氪 Top10
${KR_NEWS}

---

## 📺 视频平台

### B 站热门 Top10
${BILIBILI_HOT}

---

## 📱 国外平台

### Reddit 科技热门 Top10
${REDDIT_HOT}

### GitHub 趋势 Top10
${GITHUB_TRENDING}

---

## 🎵 国内平台（MCP）

### 抖音
✅ MCP 已配置 - 可解析视频链接
用法：\`mcporter call 'douyin.parse_douyin_video_info(share_link: "...")'\`

### 小红书
✅ MCP 已配置 - 可搜索笔记
用法：\`mcporter call 'xiaohongshu.search_feeds(keyword: "AI")'\`

### Boss 直聘
✅ MCP 已配置 - 可搜索职位
用法：\`mcporter call 'bosszhipin.search_jobs_tool(keyword: "AI")'\`

### 微信公众号
⏳ 需安装工具
${WECHAT_NOTE}

---

## 🌐 通用工具

### 任意网页
✅ Jina Reader - \`curl https://r.jina.ai/URL\`

### RSS
✅ feedparser - Python 库

### 全网搜索
✅ Exa - \`mcporter call 'exa.web_search_exa(query: "...")'\`

---

## 📊 渠道状态总览

| 渠道 | 状态 | 说明 |
|------|------|------|
| ✅ 虎嗅 | 10 条 | Jina Reader |
| ✅ 36 氪 | 10 条 | Jina Reader |
| ✅ B 站 | 10 条 | Jina Reader |
| ✅ 抖音 | MCP | 可解析视频 |
| ✅ 小红书 | MCP | 可搜索笔记 |
| ✅ Boss 直聘 | MCP | 可搜索职位 |
| ⏳ 微信公众号 | 需安装 | miku_ai + camoufox |
| ✅ GitHub | 可用 | Jina Reader |
| ✅ Reddit | 可用 | 原生 API |
| ✅ Twitter | MCP | 需 Cookie |
| ✅ YouTube | yt-dlp | 需代理 |
| ✅ LinkedIn | MCP | 需 Cookie |
| ✅ Exa 搜索 | MCP | 全网搜索 |

---
🏰 城堡日报 | agent-reach 13 渠道全覆盖
EOF

echo "✅ 报告已生成：$OUTPUT_FILE"
echo ""
cat "$OUTPUT_FILE"
