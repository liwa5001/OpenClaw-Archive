#!/bin/bash
# 成长堡每日学习计划提醒脚本
# 每天早上 8:00 发送：成长问卷 + 学习计划 + 考题

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/growth-daily-plan.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 成长堡每日学习计划发送开始 ==="

# 获取本机 IP
LOCAL_IP=$(node -e "const os = require('os'); const interfaces = os.networkInterfaces(); for (const name of Object.keys(interfaces)) { for (const iface of interfaces[name]) { if (iface.family === 'IPv4' && !iface.internal) { console.log(iface.address); process.exit(0); } } }" 2>/dev/null || echo "localhost")

TODAY=$(date '+%Y-%m-%d')

# 计算 12 周计划进度
START_DATE="2026-03-10"
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s 2>/dev/null || echo "1773091200")
NOW_TS=$(date +%s)
DAYS_ELAPSED=$(( (NOW_TS - START_TS) / 86400 ))
WEEK_NUM=$(( DAYS_ELAPSED / 7 + 1 ))
DAY_NUM=$(( DAYS_ELAPSED % 7 + 1 ))

# 根据周数获取当天学习计划
get_daily_plan() {
    local week=$1
    local day=$2
    
    if [ "$week" -eq 1 ]; then
        case "$day" in
            1) echo "OpenClaw 架构认知|OC-01|BV1jEAaz3E6K|10min|60min|理解整体架构|https://www.bilibili.com/video/BV1jEAaz3E6K/" ;;
            2) echo "OpenClaw 安装配置|OC-02|BV1TpAZzeEiZ|前 25min|90min|完成安装|https://www.bilibili.com/video/BV1TpAZzeEiZ/" ;;
            3) echo "OpenClaw 深入实践|OC-02|BV1TpAZzeEiZ|后 28min|60min|配置 Skills|https://www.bilibili.com/video/BV1TpAZzeEiZ/" ;;
            4) echo "Skill 开发基础|OC-03|BV1G3FNznEiS|前 10min|90min|理解原理|https://www.bilibili.com/video/BV1G3FNznEiS/" ;;
            5) echo "Skill 实战练习|OC-03|BV1G3FNznEiS|后 9min|60min|编写 1 个 Skill|https://www.bilibili.com/video/BV1G3FNznEiS/" ;;
            6) echo "健康堡 MVP 开发|实践|无视频|90min|MVP 原型|" ;;
            7) echo "W1 复习 + 测试|综合复习|60min|测试报告|通过率 85%|" ;;
        esac
    elif [ "$week" -eq 2 ]; then
        case "$day" in
            1) echo "Claude 基础使用|CA-06|BV1zqeMzfEiQ|60min|3 个应用场景|https://www.bilibili.com/video/BV1zqeMzfEiQ/" ;;
            2) echo "AI 习惯养成|JS-05|31cp_OXKzkI|60min|3 个习惯实践|https://www.youtube.com/watch?v=31cp_OXKzkI" ;;
            3) echo "AI 原生思维|JS-06|E7YiKBeOneo|60min|思维转变|https://www.youtube.com/watch?v=E7YiKBeOneo" ;;
            4) echo "Prompt 工程基础|CA-03|jC4v5AS4RIM|90min|Prompt 公式|https://www.youtube.com/watch?v=jC4v5AS4RIM" ;;
            5) echo "ChatGPT 进阶|CA-04|bkf3XBOj2PE|60min|10 个技巧|https://www.youtube.com/watch?v=bkf3XBOj2PE" ;;
            6) echo "Claude Code 入门|CA-02|BV14rzQB9EJj|90min|1 个脚本|https://www.bilibili.com/video/BV14rzQB9EJj/" ;;
            7) echo "W2 复习 + 测试|综合复习|60min|测试报告|通过率 85%|" ;;
        esac
    else
        echo "复习/自由学习|自主安排|自主安排|90min|本周总结|完成总结|"
    fi
}

PLAN_INFO=$(get_daily_plan $WEEK_NUM $DAY_NUM)
IFS='|' read -r TOPIC VIDEO_ID BV_ID DURATION TARGET GOAL VIDEO_URL <<< "$PLAN_INFO"

# 生成视频链接
if [ -n "$VIDEO_URL" ] && [ "$VIDEO_URL" != "" ]; then
    VIDEO_TEXT="🎥 **今日视频链接：**
👉 $VIDEO_URL

⏱️ **观看要求：** $DURATION"
else
    VIDEO_TEXT="📚 **今日为实践日，无视频内容**"
fi

# 检查并启动服务器
if ! curl -s "http://localhost:8896" > /dev/null 2>&1; then
    log "启动成长堡服务器..."
    cd "$WORKSPACE/growth-form"
    nohup node server.js > "$WORKSPACE/logs/growth-server.log" 2>&1 &
    sleep 2
    log "✅ 成长堡服务器已启动"
else
    log "成长堡服务器已运行"
fi

if ! curl -s "http://localhost:8898" > /dev/null 2>&1; then
    log "启动考题服务器..."
    cd "$WORKSPACE/quiz-form"
    nohup node server.js > "$WORKSPACE/logs/quiz-server.log" 2>&1 &
    sleep 2
    log "✅ 考题服务器已启动"
else
    log "考题服务器已运行"
fi

# 飞书消息（纯文本，链接可点击）
FEISHU_MESSAGE="📚 **成长堡每日学习计划提醒 | $TODAY**

**12 周计划：** 第${WEEK_NUM}周 第${DAY_NUM}天

━━━━━━━━━━━━━━━━━━

📝 **成长堡每日复盘**

花 3 分钟回顾学习成长~

👉 http://${LOCAL_IP}:8896/

【填写内容】
📖 今日学习 | ⭐ 质量自评 | 📝 今日产出
📝 每日题目 | 🎥 视频链接 | 📋 考题记录

━━━━━━━━━━━━━━━━━━

📖 **今日学习任务**

**主题：** $TOPIC
**目标：** $GOAL
**时长：** ${TARGET}

$VIDEO_TEXT

━━━━━━━━━━━━━━━━━━

📝 **每日考题**

完成学习后，点击链接答题：

👉 http://${LOCAL_IP}:8898/

（HTML 表单，答案直接记录到学习档案）

━━━━━━━━━━━━━━━━━━

🔗 **完整视频链接汇总**

**OpenClaw 系列：**
• [OC-01 一个视频搞懂 OpenClaw！](https://www.bilibili.com/video/BV1jEAaz3E6K/)
• [OC-02 保姆级 OpenClaw 全网最细教学](https://www.bilibili.com/video/BV1TpAZzeEiZ/)
• [OC-03 手把手彻底学会 Agent Skills！](https://www.bilibili.com/video/BV1G3FNznEiS/)

**创哥 AI 系列：**
• [CG-01 15 分钟用 OpenClaw 搭建人生系统](https://www.bilibili.com/video/BV14TPgzAEvo/)
• [CG-02 一个视频让你 OpenClaw 技术瞬间超越 90% 的人](https://www.bilibili.com/video/BV17mAUzxETS/)
• [CG-03 在 AI 时代，程序员怎么做技术选型？](https://www.bilibili.com/video/BV16k7tzuEqh/)
• [CG-04 谁才是 AI 生成网站的最强王者？](https://www.bilibili.com/video/BV1yv78zQERh/)
• [CG-05 Cursor 1.0 更新，确实有亮点](https://www.bilibili.com/video/BV1NLTyziERN/)

**Jeff Su 系列：**
• [JS-01 How to Create Cinematic AI Videos](https://www.youtube.com/watch?v=0-0gFuDwmXI)
• [JS-02 Complete AI Video Editing Tutorial](https://www.youtube.com/watch?v=-mBKM7Aqmy8)
• [JS-03 Learn 80% of NotebookLM](https://www.youtube.com/watch?v=EOmgC3-hznM)
• [JS-04 I Switched 50% of My AI Work to Claude](https://www.youtube.com/watch?v=RudrWy9uPZE)
• [JS-05 3 AI Habits So Powerful](https://www.youtube.com/watch?v=31cp_OXKzkI)
• [JS-06 Give Me 9 Minutes, I'll Make You AI-Native](https://www.youtube.com/watch?v=E7YiKBeOneo)

**剪映教程：**
• [VM-01 剪映教程 - 一口气学会剪辑](https://www.bilibili.com/video/BV1CSpcz7ELp/)

━━━━━━━━━━━━━━━━━━

💡 **建议流程：**
1️⃣ 填写成长堡复盘（3 分钟）
2️⃣ 观看视频学习（$DURATION）
3️⃣ 完成实践任务
4️⃣ 答题巩固（HTML 表单）

---
🏰 城堡成长堡 | 持续学习，日拱一卒！
"

# Web UI 消息（Markdown 格式，链接可点击）
WEBCHAT_MESSAGE="📚 **成长堡每日学习任务 | $TODAY (W${WEEK_NUM}D${DAY_NUM})**

**主题：** $TOPIC  
**目标：** $GOAL  
**时长：** ${TARGET}

---

## 📋 详细安排

| 时段 | 内容 | 时长 |
|------|------|------|
| 上午 | OpenClaw | 30min |
| 下午 | 创哥 AI | 30min |
| 晚上 | Claude AI | 30min |
| 睡前 | 剪映 | 30min |

---

## 🔗 学习链接

$VIDEO_TEXT

---

## 📺 完整视频链接汇总

### OpenClaw 系列
| 编号 | 视频名称 | 链接 |
|------|---------|------|
| OC-01 | 一个视频搞懂 OpenClaw！ | [📺 B 站](https://www.bilibili.com/video/BV1jEAaz3E6K/) |
| OC-02 | 保姆级 OpenClaw 全网最细教学 | [📺 B 站](https://www.bilibili.com/video/BV1TpAZzeEiZ/) |
| OC-03 | 手把手彻底学会 Agent Skills！ | [📺 B 站](https://www.bilibili.com/video/BV1G3FNznEiS/) |

### 创哥 AI 系列
| 编号 | 视频名称 | 链接 |
|------|---------|------|
| CG-01 | 15 分钟用 OpenClaw 搭建人生系统 | [📺 B 站](https://www.bilibili.com/video/BV14TPgzAEvo/) |
| CG-02 | 一个视频让你 OpenClaw 技术瞬间超越 90% 的人 | [📺 B 站](https://www.bilibili.com/video/BV17mAUzxETS/) |
| CG-03 | 在 AI 时代，程序员怎么做技术选型？ | [📺 B 站](https://www.bilibili.com/video/BV16k7tzuEqh/) |
| CG-04 | 谁才是 AI 生成网站的最强王者？ | [📺 B 站](https://www.bilibili.com/video/BV1yv78zQERh/) |
| CG-05 | Cursor 1.0 更新，确实有亮点 | [📺 B 站](https://www.bilibili.com/video/BV1NLTyziERN/) |

### Jeff Su 系列
| 编号 | 视频名称 | 链接 |
|------|---------|------|
| JS-01 | How to Create Cinematic AI Videos | [📺 YouTube](https://www.youtube.com/watch?v=0-0gFuDwmXI) |
| JS-02 | Complete AI Video Editing Tutorial | [📺 YouTube](https://www.youtube.com/watch?v=-mBKM7Aqmy8) |
| JS-03 | Learn 80% of NotebookLM in Under 13 Minutes | [📺 YouTube](https://www.youtube.com/watch?v=EOmgC3-hznM) |
| JS-04 | I Switched 50% of My AI Work to Claude | [📺 YouTube](https://www.youtube.com/watch?v=RudrWy9uPZE) |
| JS-05 | 3 AI Habits So Powerful | [📺 YouTube](https://www.youtube.com/watch?v=31cp_OXKzkI) |
| JS-06 | Give Me 9 Minutes, I'll Make You AI-Native | [📺 YouTube](https://www.youtube.com/watch?v=E7YiKBeOneo) |

### 剪映教程系列
| 编号 | 视频名称 | 链接 |
|------|---------|------|
| VM-01 | 剪映教程 - 一口气学会剪辑 | [📺 B 站](https://www.bilibili.com/video/BV1CSpcz7ELp/) |

---

## 🎯 今日产出
- [ ] 完成视频观看
- [ ] 实践任务
- [ ] 成长堡复盘
- [ ] 每日考题

---

## 📝 快速入口

**成长堡复盘表单：** http://${LOCAL_IP}:8896/  
**每日考题表单：** http://${LOCAL_IP}:8898/

---

💡 **建议流程：** 填写复盘 → 观看视频 → 实践任务 → 答题巩固

🏰 城堡成长堡 | 持续学习，日拱一卒！
"

# 发送飞书消息
/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$FEISHU_MESSAGE"
log "✅ 成长堡学习计划已发送 (飞书)"

# Web UI 消息通过 sessions_send 发送到当前会话
# 注意：webchat 渠道不需要 target，消息会自动路由到当前会话
cat > /tmp/webchat-message.txt << WEBCHAT_EOF
$WEBCHAT_MESSAGE
WEBCHAT_EOF

log "✅ 成长堡学习计划已发送 (Web UI 通过定时任务自动推送)"
log "=== 成长堡每日学习计划发送完成 ==="
