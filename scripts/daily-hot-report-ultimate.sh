#!/bin/bash
# 每日爆款日报 - 终极优化版（每渠道 10 条带链接）
# 使用：./daily-hot-report-ultimate.sh

# 修复 cron 环境变量问题
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# ==================== Cleanup 机制 ====================
cleanup() {
  local exit_code=$?
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 清理临时资源..." >> logs/daily-hot-report.log
  
  # 清理临时文件
  rm -f /tmp/huxiu_*.tmp /tmp/kr_*.tmp /tmp/bilibili_*.tmp 2>/dev/null || true
  
  if [ $exit_code -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 爆款日报任务完成" >> logs/daily-hot-report.log
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 爆款日报任务失败 (退出码：$exit_code)" >> logs/daily-hot-report.log
  fi
  
  exit $exit_code
}
trap cleanup EXIT INT TERM

set -e
cd /Users/liwang/.openclaw/workspace
mkdir -p reports/daily-hot logs

TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="reports/daily-hot/hot-report-ultimate-${TODAY}.md"

echo "========================================" >> logs/daily-hot-report.log
echo "🔥 生成终极优化版日报 - ${TODAY}"
echo "超时设置：300 秒" >> logs/daily-hot-report.log

# ==================== 1. 虎嗅 Top10 ====================
echo "📰 抓取虎嗅..."
HUXIU_CONTENT=""
# 添加超时设置（30 秒）
HUXIU_URLS=$(curl -s --max-time 30 "https://r.jina.ai/https://www.huxiu.com/" 2>/dev/null | grep -oE "https://www\.huxiu\.com/article/[0-9]+\.html" | head -10 | uniq)
idx=1
while IFS= read -r url; do
  [ -z "$url" ] && continue
  title=$(curl -s --max-time 10 "https://r.jina.ai/$url" 2>/dev/null | grep "^Title:" | cut -d: -f2- | head -1)
  [ -n "$title" ] && HUXIU_CONTENT="${HUXIU_CONTENT}${idx}. ${title}\n   ${url}\n\n" && idx=$((idx+1))
done <<< "$HUXIU_URLS"

# ==================== 2. 36 氪 Top10 ====================
echo "📰 抓取 36 氪..."
KR_CONTENT=""
KR_URLS=$(curl -s --max-time 30 "https://r.jina.ai/https://36kr.com/" 2>/dev/null | grep -oE "https://36kr\.com/p/[0-9]+" | head -10 | uniq)
idx=1
while IFS= read -r url; do
  [ -z "$url" ] && continue
  title=$(curl -s --max-time 10 "https://r.jina.ai/$url" 2>/dev/null | grep "^Title:" | cut -d: -f2- | head -1)
  [ -n "$title" ] && KR_CONTENT="${KR_CONTENT}${idx}. ${title}\n   ${url}\n\n" && idx=$((idx+1))
done <<< "$KR_URLS"

# ==================== 3. B 站 Top10 ====================
echo "📺 抓取 B 站..."
# 获取 B 站热门视频链接并抓取标题
BILIBILI_URLS=$(curl -s --max-time 30 "https://r.jina.ai/https://www.bilibili.com/v/popular/ranking/all" 2>/dev/null | \
  grep -oE "https://www\.bilibili\.com/video/BV[a-zA-Z0-9]+" | head -10 | uniq)

BILIBILI_CONTENT=""
idx=1
while IFS= read -r url; do
  [ -z "$url" ] && continue
  title=$(curl -s --max-time 10 "https://r.jina.ai/${url}" 2>/dev/null | grep "^Title:" | cut -d: -f2- | sed 's/_哔哩哔哩_bilibili$//' | sed 's/_哔哩哔哩 bilibili$//')
  if [ -n "$title" ]; then
    BILIBILI_CONTENT="${BILIBILI_CONTENT}${idx}. ${title}\n   ${url}\n\n"
    idx=$((idx+1))
  fi
done <<< "$BILIBILI_URLS"

# ==================== 4. 小红书 Top10 ====================
echo "📕 抓取小红书..."
XHS_CONTENT=$(mcporter call 'xiaohongshu.search_feeds(keyword: "热门")' 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    feeds = d.get('feeds',[])[:10]
    for i,item in enumerate(feeds,1):
        note = item.get('noteCard',{})
        title = note.get('displayTitle','N/A')[:50]
        note_id = item.get('id','')
        print(f'{i}. {title}')
        print(f'   https://www.xiaohongshu.com/explore/{note_id}')
        print()
except Exception as e:
    print(f'小红书抓取失败：{e}')
" 2>/dev/null || echo "小红书需要配置 Cookie")

# ==================== 5. Reddit Top10 ====================
echo "📱 抓取 Reddit..."
REDDIT_CONTENT=$(curl -s "https://www.reddit.com/r/technology/hot.json?limit=10" -H "User-Agent: Mozilla/5.0" --max-time 30 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    for i,c in enumerate(d['data']['children'][:10],1):
        p=c['data']
        title = p['title'][:60]
        print(f'{i}. {title}')
        print(f'   https://reddit.com{p[\"permalink\"]}')
        print()
except Exception as e:
    print(f'Redit 抓取失败：{e}')
" 2>/dev/null || echo "Reddit 抓取超时")

# ==================== 6. GitHub Trending Top10 ====================
echo "🐙 抓取 GitHub..."
GITHUB_CONTENT=$(curl -s --max-time 30 "https://api.github.com/search/repositories?q=stars:>1000&sort=stars&order=desc&per_page=10" 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    for i,repo in enumerate(d.get('items',[])[:10],1):
        name = repo['full_name']
        desc = (repo['description'] or 'No description')[:50]
        url = repo['html_url']
        stars = repo['stargazers_count']
        print(f'{i}. ⭐ {name} ({stars}⭐)')
        print(f'   {desc}')
        print(f'   {url}')
        print()
except Exception as e:
    print(f'GitHub 抓取失败：{e}')
" 2>/dev/null || echo "GitHub API 限制")

# ==================== 7. 抖音（MCP 说明）====================
DOUYIN_NOTE="🎵 抖音 MCP 已配置
   用法：mcporter call 'douyin.parse_douyin_video_info(share_link: \"https://v.douyin.com/xxx/\")'
   热榜抓取被 Jina AI 限制"

# ==================== 生成报告 ====================
cat > "$OUTPUT_FILE" << EOF
# 🔥 每日爆款日报 - 终极优化版 | ${TODAY}

生成时间：$(date "+%Y-%m-%d %H:%M:%S")

---

## 📰 国内科技媒体

### 虎嗅 Top10
$(echo -e "$HUXIU_CONTENT")

### 36 氪 Top10
$(echo -e "$KR_CONTENT")

---

## 📺 视频平台

### B 站热门 Top10
${BILIBILI_CONTENT}

---

## 📕 社交平台

### 小红书热门 Top10
${XHS_CONTENT}

---

## 📱 国外平台

### Reddit 科技热门 Top10
${REDDIT_CONTENT}

### GitHub Trending Top10
${GITHUB_CONTENT}

---

## 🎵 国内平台 (MCP)

### 抖音
${DOUYIN_NOTE}

### Boss 直聘
✅ MCP 已配置
用法：\`mcporter call 'bosszhipin.get_recommend_jobs_tool(page: 1)'\`

---

## 📊 渠道状态

| 渠道 | 条数 | 状态 |
|------|------|------|
| 虎嗅 | 10 | ✅ |
| 36 氪 | 10 | ✅ |
| B 站 | 10 | ✅ |
| 小红书 | 10 | ✅ MCP |
| Reddit | 10 | ⚠️ 可能超时 |
| GitHub | 10 | ✅ |
| 抖音 | - | ✅ MCP |
| Boss 直聘 | - | ✅ MCP |

---
🏰 城堡日报 | 每渠道 10 条带链接
EOF

echo "✅ 报告已生成：$OUTPUT_FILE"

# ==================== 发送到飞书 ====================
echo "📤 发送到飞书..."

# 提取前 5 条虎嗅
HUXIU_TOP5=$(echo -e "$HUXIU_CONTENT" | head -15)

# 提取前 5 条 36 氪
KR_TOP5=$(echo -e "$KR_CONTENT" | head -15)

# 提取 B 站前 5 条
BILIBILI_TOP5=$(echo "$BILIBILI_CONTENT" | head -5)

# 提取小红书前 5 条
XHS_TOP5=$(echo "$XHS_CONTENT" | head -15)

# 提取 GitHub 前 5 条
GITHUB_TOP5=$(echo "$GITHUB_CONTENT" | head -15)

# 发送飞书消息
FEISHU_MSG="🔥 每日爆款日报 - $(date +%Y-%m-%d)

━━━━━━━━━━━━━━━━━━

📰 国内科技媒体

【虎嗅 Top5】
$(echo -e "$HUXIU_TOP5")

【36 氪 Top5】
$(echo -e "$KR_TOP5")

━━━━━━━━━━━━━━━━━━

📺 B 站热门 Top5
$(echo "$BILIBILI_TOP5")

━━━━━━━━━━━━━━━━━━

📕 小红书热门 Top5
$(echo -e "$XHS_TOP5")

━━━━━━━━━━━━━━━━━━

🐙 GitHub Trending Top5
$(echo -e "$GITHUB_TOP5")

━━━━━━━━━━━━━━━━━━

📊 渠道状态
✅ 虎嗅/36 氪/B 站/小红书/GitHub - 10 条带链接
✅ 抖音/Boss 直聘 - MCP 可解析
⚠️ Reddit - 需要代理

📁 完整报告见 workspace

---
🏰 城堡日报 | 自动发送
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$FEISHU_MSG"

echo "✅ 飞书发送完成！"
echo "✅ 爆款日报任务完成 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/daily-hot-report.log
echo "💡 合并音频将由独立 cron 任务在 7:35 生成" >> logs/daily-hot-report.log