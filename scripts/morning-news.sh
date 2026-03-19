#!/bin/bash
# 晨报定时任务 - 每天早上 7 点自动发送
# 使用 OpenClaw AI 动态抓取最新新闻，发送到飞书
# 
# 配置信息：
# - 发送渠道：飞书 (ou_7781abd1e83eae23ccf01fe627f0747f)
# - 停用：iMessage (2026-03-04 起)
# - 旧脚本：morning-news-ai.js (已删除 2026-03-05)
# - 命令路径：/opt/homebrew/bin/openclaw (cron 环境必需)
#
# 相关文档：/workspace/CHECKLIST.md, /workspace/HEARTBEAT.md

set -e

# 修复 cron 环境 PATH 问题 - 确保 node 和 openclaw 可用
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# ==================== Cleanup 机制 ====================
cleanup() {
  local exit_code=$?
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 清理临时资源..." >> logs/morning-news.log
  
  # 清理临时文件
  rm -f /tmp/morning-news-task.txt 2>/dev/null || true
  
  if [ $exit_code -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 晨报任务完成" >> logs/morning-news.log
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 晨报任务失败 (退出码：$exit_code)" >> logs/morning-news.log
  fi
  
  exit $exit_code
}
trap cleanup EXIT INT TERM

# ==================== 超时设置 ====================
# 整个脚本最大执行时间：5 分钟
TIMEOUT_SECONDS=300

cd /Users/liwang/.openclaw/workspace

# 创建日志目录
mkdir -p logs

echo "========================================" >> logs/morning-news.log
echo "📰 晨报任务已触发 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/morning-news.log
echo "超时设置：${TIMEOUT_SECONDS}秒" >> logs/morning-news.log

# 使用 OpenClaw 执行 AI 新闻抓取任务
cat > /tmp/morning-news-task.txt << 'TASK'
# 晨报任务 - 立即执行

请执行以下任务：

1. 使用 web_fetch 抓取以下新闻源的最新内容：
   - 澎湃新闻：https://www.thepaper.cn/
   - 联合早报：https://www.zaobao.com/
   - 虎嗅：https://www.huxiu.com/
   - 钛媒体：https://www.tmtpost.com/new
   - 新华网：https://www.xinhuanet.com/
   - 人民网：https://www.people.com.cn/
   - IT 之家：https://www.ithome.com/
   - 新华网汽车：https://www.xinhuanet.com/auto/
   - 汽车之家：https://www.autohome.com.cn/

2. 整理 4 类新闻，每类 5 条：
   - 🌍 国际新闻
   - 🇨🇳 国内新闻
   - 🤖 AI 新闻
   - 🚗 汽车新闻

3. 链接验证规则：
   - 必须包含 /article/ 或 /newsDetail 或类似文章路径
   - 过滤掉首页链接和无效链接
   - 澎湃新闻下划线编码：_ → %5F

4. 生成飞书格式（Markdown 链接）：
   [新闻标题](https://编码后的链接)

5. 通过飞书发送（msg_type: text，Markdown 格式）：
   - 目标：ou_7781abd1e83eae23ccf01fe627f0747f
   - 格式：每条新闻用 [标题](链接) 格式

6. 记录到 memory/$(date +%Y-%m-%d).md

输出格式示例：
```
📰 晨报 - YYYY 年 M 月 D 日

🌍 国际新闻

[标题 1](链接 1)

[标题 2](链接 2)

...
```
TASK

# 调用 OpenClaw 执行任务
echo "🤖 正在调用 AI 执行新闻抓取..." >> logs/morning-news.log

# 通过 OpenClaw agent 执行任务（使用完整路径，避免 cron 环境中找不到命令）
# 注意：--session-id 使用固定值保证晨报使用同一会话，保持上下文连贯
/opt/homebrew/bin/openclaw agent --session-id "morning-news" --message "$(cat /tmp/morning-news-task.txt)" >> logs/morning-news.log 2>&1 || echo "⚠️ AI 任务执行失败" >> logs/morning-news.log

echo "✅ 晨报任务完成 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/morning-news.log
echo "⏳ 等待爆款日报生成后合并音频..." >> logs/morning-news.log
