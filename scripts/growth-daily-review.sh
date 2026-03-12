#!/bin/bash
# 成长堡每日复盘脚本 - 每天晚上 21:00 发送

set -e

cd /Users/liwang/.openclaw/workspace

DATE=$(date +%Y-%m-%d)
START_DATE="2026-03-09"

# 计算第几周第几天
START_TS=$(date -j -f "%Y-%m-%d" "$START_DATE" +%s)
TODAY_TS=$(date -j -f "%Y-%m-%d" "$DATE" +%s)
DAYS_ELAPSED=$(( (TODAY_TS - START_TS) / 86400 + 1 ))
WEEK_NUM=$(( (DAYS_ELAPSED - 1) / 7 + 1 ))
DAY_IN_WEEK=$(( (DAYS_ELAPSED - 1) % 7 + 1 ))

echo "📚 成长堡每日复盘 | $DATE"
echo "========================"
echo "第 $WEEK_NUM 周 第 $DAY_IN_WEEK 天"

# 发送复盘问卷到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "📚 成长堡 | 今日复盘 | $DATE

【完成情况】
A. 今天学习了吗？
   回复数字：0=未学习 | 1=有学习

   如选 1，请补充：
   - OpenClaw: ____分钟 (内容：________)
   - Claude AI: ____分钟 (内容：________)
   - 视频制作：____分钟 (内容：________)

B. 学习质量自评 (1-5 分)
   1=很差 | 2=一般 | 3=不错 | 4=很好 | 5=完美

C. 今日产出
   [ ] 学习笔记 ____ 页
   [ ] 实操练习 ____ 次
   [ ] 作品/代码 ____ 个

D. 遇到的问题
   ________________________
   (如无，填"无")

E. 明日计划调整
   ________________________
   (可选填)

═══════════════════════════
📝 回复示例：
A1
OpenClaw: 45 分钟 (OC-02 视频 P3-P5)
Claude AI: 30 分钟 (Prompt 模板练习)
视频制作：20 分钟 (PR 基础 P1-P2)
B4
C 笔记 2 页，实操 3 次，作品 0 个
D 无
E 明天增加视频制作时间

💪 期待你的复盘！
"

echo "✅ 复盘问卷已发送（飞书） - $(date)"
