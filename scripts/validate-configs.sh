#!/bin/bash
# 配置验证脚本 - 检查所有活跃配置是否正常
# 用法：./scripts/validate-configs.sh [--fix]

set -e

cd /Users/liwang/.openclaw/workspace

CONFIG_FILE="config/active-configs.json"
LOG_FILE="logs/config-validation.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mkdir -p logs

echo "🔍 配置验证 - $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"

errors=0
warnings=0

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ 配置文件不存在：$CONFIG_FILE${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# 检查活跃任务
echo "📋 检查活跃任务..." | tee -a "$LOG_FILE"

# 检查晨报脚本
if [ -f "scripts/morning-news.sh" ]; then
    echo -e "${GREEN}✅ 晨报脚本存在${NC}" | tee -a "$LOG_FILE"
    
    # 检查脚本是否有执行权限
    if [ -x "scripts/morning-news.sh" ]; then
        echo -e "${GREEN}✅ 晨报脚本有执行权限${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️  晨报脚本缺少执行权限${NC}" | tee -a "$LOG_FILE"
        ((warnings++))
    fi
    
    # 检查脚本中是否使用完整路径
    if grep -q "/opt/homebrew/bin/openclaw" "scripts/morning-news.sh"; then
        echo -e "${GREEN}✅ 晨报脚本使用完整命令路径${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}❌ 晨报脚本未使用完整命令路径（cron 环境会失败）${NC}" | tee -a "$LOG_FILE"
        ((errors++))
    fi
else
    echo -e "${RED}❌ 晨报脚本不存在${NC}" | tee -a "$LOG_FILE"
    ((errors++))
fi

# 检查旧脚本是否已删除
if [ -f "scripts/morning-news-ai.js" ]; then
    echo -e "${RED}❌ 旧脚本 morning-news-ai.js 仍存在（应删除）${NC}" | tee -a "$LOG_FILE"
    ((errors++))
else
    echo -e "${GREEN}✅ 旧脚本已删除${NC}" | tee -a "$LOG_FILE"
fi

# 检查其他健康相关脚本
for script in health-report.sh training-reminder.sh analyze-workout.sh update-training-plan.sh; do
    if [ -f "scripts/$script" ]; then
        echo -e "${GREEN}✅ 脚本存在：$script${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️  脚本不存在：$script${NC}" | tee -a "$LOG_FILE"
        ((warnings++))
    fi
done

# 检查 crontab
echo "" | tee -a "$LOG_FILE"
echo "⏰ 检查 crontab 配置..." | tee -a "$LOG_FILE"

if crontab -l 2>/dev/null | grep -q "morning-news.sh"; then
    echo -e "${GREEN}✅ 晨报任务已添加到 crontab${NC}" | tee -a "$LOG_FILE"
    
    # 检查是否使用完整路径
    if crontab -l 2>/dev/null | grep "morning-news.sh" | grep -q "cd.*workspace"; then
        echo -e "${GREEN}✅ crontab 设置了正确的工作目录${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️  crontab 可能缺少工作目录设置${NC}" | tee -a "$LOG_FILE"
        ((warnings++))
    fi
else
    echo -e "${RED}❌ 晨报任务未添加到 crontab${NC}" | tee -a "$LOG_FILE"
    ((errors++))
fi

# 检查 memory 文件
echo "" | tee -a "$LOG_FILE"
echo "📝 检查记忆文件..." | tee -a "$LOG_FILE"

today=$(date +%Y-%m-%d)
if [ -f "memory/$today.md" ]; then
    echo -e "${GREEN}✅ 今日记忆文件存在：memory/$today.md${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${YELLOW}⚠️  今日记忆文件不存在（可选）${NC}" | tee -a "$LOG_FILE"
    ((warnings++))
fi

# 总结
echo "" | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"
echo "📊 验证结果：" | tee -a "$LOG_FILE"
echo -e "  错误：${RED}$errors${NC}" | tee -a "$LOG_FILE"
echo -e "  警告：${YELLOW}$warnings${NC}" | tee -a "$LOG_FILE"

if [ $errors -gt 0 ]; then
    echo -e "${RED}❌ 验证失败，请修复上述错误${NC}" | tee -a "$LOG_FILE"
    exit 1
elif [ $warnings -gt 0 ]; then
    echo -e "${YELLOW}⚠️  验证通过，但有警告项${NC}" | tee -a "$LOG_FILE"
    exit 0
else
    echo -e "${GREEN}✅ 所有配置验证通过${NC}" | tee -a "$LOG_FILE"
    exit 0
fi
