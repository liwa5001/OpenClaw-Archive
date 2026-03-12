#!/bin/bash
# 晨报自检脚本 - 每天早上 6:55 自动运行（晨报前 5 分钟）
# 用途：检查晨报配置、网络状态，确保 7:00 晨报不掉链子

set -e

cd /Users/liwang/.openclaw/workspace
mkdir -p logs

echo "🔍 晨报自检开始 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/morning-news-check.log

# 初始化检查结果
CHECKS_PASSED=0
CHECKS_FAILED=0
ISSUES=()

# 1. 检查 OpenClaw 命令是否可用
echo "1️⃣ 检查 OpenClaw 命令..." >> logs/morning-news-check.log
if command -v openclaw >/dev/null 2>&1 || [ -f /opt/homebrew/bin/openclaw ]; then
    echo "   ✅ OpenClaw 命令正常" >> logs/morning-news-check.log
    ((CHECKS_PASSED++))
else
    echo "   ❌ OpenClaw 命令不可用" >> logs/morning-news-check.log
    ISSUES+=("OpenClaw 命令不可用")
    ((CHECKS_FAILED++))
fi

# 2. 检查飞书配置
echo "2️⃣ 检查飞书配置..." >> logs/morning-news-check.log
if grep -q "feishu" ~/.openclaw/openclaw.json 2>/dev/null && grep -q "ou_7781abd1e83eae23ccf01fe627f0747f" ~/.openclaw/openclaw.json 2>/dev/null; then
    echo "   ✅ 飞书配置正常" >> logs/morning-news-check.log
    ((CHECKS_PASSED++))
else
    echo "   ❌ 飞书配置异常" >> logs/morning-news-check.log
    ISSUES+=("飞书配置异常")
    ((CHECKS_FAILED++))
fi

# 3. 检查新闻源可访问性（抽样检查 3 个）
echo "3️⃣ 检查新闻源..." >> logs/morning-news-check.log
NEWS_SOURCES=(
    "https://www.thepaper.cn/"
    "https://www.zaobao.com/"
    "https://www.huxiu.com/"
)
NEWS_OK=0
for url in "${NEWS_SOURCES[@]}"; do
    if curl -s --max-time 5 "$url" >/dev/null 2>&1; then
        ((NEWS_OK++))
    fi
done
if [ $NEWS_OK -ge 2 ]; then
    echo "   ✅ 新闻源可访问 ($NEWS_OK/3)" >> logs/morning-news-check.log
    ((CHECKS_PASSED++))
else
    echo "   ⚠️ 新闻源访问异常 ($NEWS_OK/3)" >> logs/morning-news-check.log
    ISSUES+=("新闻源访问异常")
    ((CHECKS_FAILED++))
fi

# 4. 检查磁盘空间
echo "4️⃣ 检查磁盘空间..." >> logs/morning-news-check.log
DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
if [[ "$DISK_FREE" =~ ^[0-9]+[GT] ]]; then
    echo "   ✅ 磁盘空间充足 ($DISK_FREE)" >> logs/morning-news-check.log
    ((CHECKS_PASSED++))
else
    echo "   ⚠️ 磁盘空间紧张 ($DISK_FREE)" >> logs/morning-news-check.log
    ISSUES+=("磁盘空间紧张")
    ((CHECKS_FAILED++))
fi

# 5. 检查 Gateway 状态
echo "5️⃣ 检查 Gateway 状态..." >> logs/morning-news-check.log
if pgrep -f "openclaw.*gateway" >/dev/null 2>&1; then
    echo "   ✅ Gateway 运行中" >> logs/morning-news-check.log
    ((CHECKS_PASSED++))
else
    echo "   ❌ Gateway 未运行" >> logs/morning-news-check.log
    ISSUES+=("Gateway 未运行")
    ((CHECKS_FAILED++))
    # 尝试自动重启
    echo "   🔄 尝试重启 Gateway..." >> logs/morning-news-check.log
    if /opt/homebrew/bin/openclaw gateway restart >/dev/null 2>&1; then
        echo "   ✅ Gateway 重启成功" >> logs/morning-news-check.log
    else
        echo "   ❌ Gateway 重启失败" >> logs/morning-news-check.log
    fi
fi

# 6. 检查晨报脚本
echo "6️⃣ 检查晨报脚本..." >> logs/morning-news-check.log
if [ -x /Users/liwang/.openclaw/workspace/scripts/morning-news.sh ]; then
    echo "   ✅ 晨报脚本可执行" >> logs/morning-news-check.log
    ((CHECKS_PASSED++))
else
    echo "   ❌ 晨报脚本不可执行" >> logs/morning-news-check.log
    ISSUES+=("晨报脚本不可执行")
    ((CHECKS_FAILED++))
fi

# 生成检查报告
echo "" >> logs/morning-news-check.log
echo "📊 检查结果：$CHECKS_PASSED 通过，$CHECKS_FAILED 失败" >> logs/morning-news-check.log

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "⚠️ 发现问题:" >> logs/morning-news-check.log
    for issue in "${ISSUES[@]}"; do
        echo "   - $issue" >> logs/morning-news-check.log
    done
    echo "⚠️ 晨报自检发现 $CHECKS_FAILED 个问题，请检查配置" >> logs/morning-news-check.log
else
    echo "✅ 所有检查通过，晨报准备就绪！" >> logs/morning-news-check.log
fi

echo "✅ 晨报自检完成 - $(date)" >> logs/morning-news-check.log
echo "---" >> logs/morning-news-check.log

# 输出到控制台（调试用）
cat logs/morning-news-check.log | tail -20
