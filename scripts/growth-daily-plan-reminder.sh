#!/bin/bash
# 成长堡每日学习计划提醒脚本
# 每天早上 8:00 发送当天学习计划、视频链接和考题

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/growth-daily-plan.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 成长堡每日学习计划发送开始 ==="

# 获取今天日期和星期
TODAY=$(date '+%Y-%m-%d')
WEEKDAY=$(date '+%u')  # 1=周一，7=周日

# 计算 12 周计划进度
START_DATE="2026-03-10"
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s 2>/dev/null || echo "1773091200")
NOW_TS=$(date +%s)
DAYS_ELAPSED=$(( (NOW_TS - START_TS) / 86400 ))
WEEK_NUM=$(( DAYS_ELAPSED / 7 + 1 ))
DAY_NUM=$(( DAYS_ELAPSED % 7 + 1 ))

# 根据周数和天数获取当天学习计划
get_daily_plan() {
    local week=$1
    local day=$2
    
    # W1D1-W1D7 (第 1 周)
    if [ "$week" -eq 1 ]; then
        case "$day" in
            1) echo "OpenClaw 架构认知|OC-01|BV1jEAaz3E6K|10min|60min|理解整体架构" ;;
            2) echo "OpenClaw 安装配置|OC-02|BV1TpAZzeEiZ|前 25min|90min|完成安装" ;;
            3) echo "OpenClaw 深入实践|OC-02|BV1TpAZzeEiZ|后 28min|60min|配置 Skills" ;;
            4) echo "Skill 开发基础|OC-03|BV1G3FNznEiS|前 10min|90min|理解原理" ;;
            5) echo "Skill 实战练习|OC-03|BV1G3FNznEiS|后 9min|60min|编写 1 个 Skill" ;;
            6) echo "健康堡 MVP 开发|实践|无视频|90min|MVP 原型" ;;
            7) echo "W1 复习 + 测试|综合复习|60min|测试报告|通过率 85%" ;;
        esac
    # W2D1-W2D7 (第 2 周)
    elif [ "$week" -eq 2 ]; then
        case "$day" in
            1) echo "Claude 基础使用|CA-06|12:44|60min|3 个应用场景" ;;
            2) echo "AI 习惯养成|CA-07|10:50|60min|3 个习惯实践" ;;
            3) echo "AI 原生思维|CA-08|8:55|60min|思维转变" ;;
            4) echo "Prompt 工程基础|CA-04|8:30|90min|Prompt 公式" ;;
            5) echo "ChatGPT 进阶|CA-05|8:45|60min|10 个技巧" ;;
            6) echo "Claude Code 入门|CA-02|前 20min|90min|1 个脚本" ;;
            7) echo "W2 复习 + 测试|综合复习|60min|测试报告|通过率 85%" ;;
        esac
    # W3D1-W3D7 (第 3 周)
    elif [ "$week" -eq 3 ]; then
        case "$day" in
            1) echo "提示词核心公式|CA-04|完整|60min|5 个 Prompt" ;;
            2) echo "Claude 实战应用|CA-06|完整|90min|1 个任务" ;;
            3) echo "提示词技巧进阶|CA-05|2-4h|60min|10 个技巧" ;;
            4) echo "Claude Code 实战|CA-02|前 20min|90min|1 个脚本" ;;
            5) echo "工作流设计|CA-06|完整|60min|工作流方案" ;;
            6) echo "Castle 6 集成|实践|90min|Claude 辅助|实际效果" ;;
            7) echo "W3 复习 + 测试|Prompt 测试|60min|测试报告|通过率 90%" ;;
        esac
    # W4D1-W4D7 (第 4 周)
    elif [ "$week" -eq 4 ]; then
        case "$day" in
            1) echo "MCP 协议学习|CA-02|20-40min|60min|MCP 笔记" ;;
            2) echo "SubAgent 开发|CA-02|40min-结束|90min|1 个 SubAgent" ;;
            3) echo "Hook 系统|CA-02 补充|60min|Hook 示例" ;;
            4) echo "企业级案例|CA-03|前 2h|90min|案例分析" ;;
            5) echo "实战项目 (上)|综合应用|90min|项目原型" ;;
            6) echo "实战项目 (下)|综合应用|90min|完整项目" ;;
            7) echo "阶段测试 (W1-4)|综合考核|90min|测试报告|通过 85%" ;;
        esac
    # 默认：复习周或自由安排
    else
        echo "复习/自由学习|自主安排|自主安排|90min|本周总结|完成总结"
    fi
}

# 获取当天计划
PLAN_INFO=$(get_daily_plan $WEEK_NUM $DAY_NUM)
IFS='|' read -r TOPIC VIDEO_ID BV_ID DURATION TARGET OUTPUT GOAL <<< "$PLAN_INFO"

# 生成视频链接
if [ "$BV_ID" != "无视频" ] && [ -n "$BV_ID" ]; then
    VIDEO_URL="https://www.bilibili.com/video/$BV_ID"
    VIDEO_TEXT="🎥 **视频链接：**
$VIDEO_URL

⏱️ **观看要求：** $DURATION
📍 **学习重点：** $TOPIC"
else
    VIDEO_TEXT="📚 **今日为实践日，无视频内容**
💡 重点完成实践任务和产出"
fi

# 生成考题（根据周数）
get_daily_quiz() {
    local week=$1
    local day=$2
    
    if [ "$week" -eq 1 ]; then
        case "$day" in
            1) echo "1. OpenClaw 的核心架构是什么？（简述 3 个核心组件）
2. Agent 和 SubAgent 的区别是什么？
3. Skills 系统的作用是什么？" ;;
            2) echo "1. 如何安装 OpenClaw？写出关键命令
2. 如何配置 Feishu 渠道？
3. 如何验证安装成功？" ;;
            3) echo "1. 如何创建一个自定义 Skill？
2. Skill 的目录结构是怎样的？
3. 如何让 Skill 支持图片处理？" ;;
            4) echo "1. 编写一个 Skill，实现天气查询功能
2. 编写一个 Skill，实现每日晨报功能
3. 如何让 Skill 支持定时任务？" ;;
            5) echo "1. 优化健康堡 HTML 表单系统
2. 添加数据校验功能
3. 实现提交后自动分析" ;;
            6) echo "1. 完成健康堡 MVP 开发
2. 实现表单提交和数据保存
3. 实现飞书消息发送" ;;
            7) echo "1. 总结本周学习内容（200 字）
2. 列出遇到的 3 个问题和解决方案
3. 制定下周学习计划" ;;
        esac
    elif [ "$week" -eq 2 ]; then
        case "$day" in
            1) echo "1. Claude 的核心优势是什么？
2. 列举 3 个 Claude 的实际应用场景
3. 如何编写有效的 System Prompt？" ;;
            2) echo "1. 描述 3 个 AI 使用习惯
2. 如何将 AI 融入日常工作流？
3. AI 辅助决策的案例" ;;
            3) echo "1. 什么是 AI 原生思维？
2. 传统思维 vs AI 原生思维的区别
3. 如何培养 AI 原生思维？" ;;
            4) echo "1. 写出 Prompt 核心公式
2. 编写 5 个结构化 Prompt
3. 优化一个现有 Prompt" ;;
            5) echo "1. 列举 ChatGPT 的 10 个进阶技巧
2. 实际应用其中 3 个技巧
3. 对比 ChatGPT 和 Claude 的差异" ;;
            6) echo "1. Claude Code 的核心功能是什么？
2. 编写一个 CLI 脚本
3. 如何将 Claude 集成到项目中？" ;;
            7) echo "1. 总结本周 AI 学习心得
2. 编写 3 个优质 Prompt 模板
3. 展示 Claude 辅助完成的任务" ;;
        esac
    else
        echo "1. 总结本周核心学习内容
2. 完成一个实践项目
3. 编写学习总结报告"
    fi
}

QUIZ_CONTENT=$(get_daily_quiz $WEEK_NUM $DAY_NUM)

# 生成飞书消息
MESSAGE="📚 **成长堡每日学习计划 | $TODAY**

**12 周计划：** 第${WEEK_NUM}周 第${DAY_NUM}天
**今日主题：** $TOPIC
**目标产出：** $OUTPUT
**学习时长：** ${TARGET}

---

$VIDEO_TEXT

---

📝 **今日考题**

\`\`\`
$QUIZ_CONTENT
\`\`\`

**👉 点击链接完成考题：**
http://192.168.2.58:8898/

（考题 HTML 表单，答案直接提交记录）

---

💡 **学习建议**
- 📺 先看视频，理解核心概念
- 💻 边学边练，完成实践任务
- 📝 认真答题，巩固知识点
- ⏰ 合理分配时间，确保完成目标

---

🏰 城堡成长堡 | 持续学习，日拱一卒！
"

log "发送学习计划到飞书..."

# 发送飞书消息
/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"

log "✅ 成长堡学习计划已发送"
log "=== 成长堡学习计划发送完成 ==="
