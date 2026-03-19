#!/bin/bash
# 总复盘堡 - 每月总结脚本
# 发送时间：每月最后一天 20:00

set -e

cd /Users/liwang/.openclaw/workspace

MONTH=$(date +%Y-%m)
OUTPUT_DIR="data/total-review/monthly/$(date +%Y)"
REPORT_DIR="reports/total-review/monthly/$(date +%Y)"
mkdir -p "$OUTPUT_DIR" "$REPORT_DIR"

echo "🏰 总复盘堡每月总结 | $MONTH"
echo "=========================================="

# 生成月总结内容
cat > "$OUTPUT_DIR/${MONTH}-summary.md" << EOF
---
type: monthly
domain: total-review
month: $MONTH
template_version: v1.0
data_sources:
  - 健康堡
  - 成长堡
  - 每周复盘
---

# 🏰 总复盘堡 | $MONTH 月度总结

**月份：** $MONTH  
**生成时间：** $(date '+%Y-%m-%d %H:%M:%S')

---

## 【📍 报考位置 - 12 周计划进度】

EOF

# 计算 12 周计划进度
PLAN_START_DATE="2026-03-10"
START_TS=$(date -j -f "%Y-%m-%d" "$PLAN_START_DATE" +%s 2>/dev/null || echo "1741564800")
NOW_TS=$(date +%s)
DAYS_ELAPSED=$(( (NOW_TS - START_TS) / 86400 + 1 ))
PLAN_WEEK_NUM=$(( (DAYS_ELAPSED - 1) / 7 + 1 ))
PLAN_DAY_IN_WEEK=$(( (DAYS_ELAPSED - 1) % 7 + 1 ))
PROGRESS_PERCENT=$(echo "scale=1; $PLAN_WEEK_NUM * 100 / 12" | bc)

# 限制在 12 周内
if [ $PLAN_WEEK_NUM -gt 12 ]; then
  PLAN_WEEK_NUM=12
  PLAN_DAY_IN_WEEK=7
  PROGRESS_PERCENT=100
fi

cat >> "$OUTPUT_DIR/${MONTH}-summary.md" << EOF

| 项目 | 当前进度 | 总进度 | 完成度 |
|------|----------|--------|--------|
| 12 周计划 | 第${PLAN_WEEK_NUM}周 第${PLAN_DAY_IN_WEEK}天 | 12 周 84 天 | ${PROGRESS_PERCENT}% |
| 本月 | $MONTH | 12 月/年 | - |
| 今年已过 | $(date +%j)天 | 365 天 | $(echo "scale=1; $(date +%j) * 100 / 365" | bc)% |

---

## 【月度核心指标】

### 健康堡

| 指标 | 月初 | 月末 | 变化 |
|------|------|------|------|
| 体重 | 待统计 | 待统计 | 待计算 |
| 运动次数 | - | 待统计 | - |
| 睡眠均值 | - | 待统计 | - |

### 成长堡

| 指标 | 目标 | 实际 | 完成度 |
|------|------|------|--------|
| 学习时长 | 待设定 | 待统计 | -% |
| 周次进度 | W1-W4 | 待统计 | -% |
| 考题总数 | 112 题 | 待统计 | -% |

---

## 【周次回顾】

| 周次 | 主题 | 完成度 | 关键成就 |
|------|------|--------|---------|
| W1 | OpenClaw 基础 | 待统计 | 待补充 |
| W2 | Skill 开发 | 待统计 | 待补充 |
| W3 | Prompt 工程 | 待统计 | 待补充 |
| W4 | 阶段测试 | 待统计 | 待补充 |

---

## 【关联分析】

- 睡眠与学习效率相关性：待分析
- 运动与专注度相关性：待分析
- 饮食与睡眠质量相关性：待分析

---

## 【成就与里程碑】

- [ ] 连续 7 天学习达标
- [ ] 健康堡 MVP 完成
- [ ] 成长堡 W1-W4 完成

---

## 【问题与改进】

1. 待补充
2. 待补充

---

## 【下月目标】

### 健康目标
- 运动：待设定
- 睡眠：待设定
- 体重：待设定

### 学习目标
- 完成周次：W5-W8
- 学习时长：待设定
- 产出目标：待设定

---

🏰 城堡总复盘堡 | 数据驱动，持续进步！
EOF

echo "✅ 月总结已生成：$OUTPUT_DIR/${MONTH}-summary.md"

# 生成 PDF
node -e "
const fs = require('fs');
const puppeteer = require('puppeteer');
const md = fs.readFileSync('$OUTPUT_DIR/${MONTH}-summary.md', 'utf8');
let html = md.replace(/^# (.*$)/gim, '<h1>\$1</h1>').replace(/^## (.*$)/gim, '<h2>\$1</h2>').replace(/^### (.*$)/gim, '<h3>\$1</h3>').replace(/\*\*(.*?)\*\*/gim, '<strong>\$1</strong>').replace(/\[(.*?)\]\((.*?)\)/gim, '<a href=\"\$2\">\$1</a>').replace(/\|/gim, '').replace(/\n/gim, '<br>');
const full = \`<!DOCTYPE html><html><head><meta charset='UTF-8'><title>$MONTH 总复盘</title><style>body{font-family:system-ui;padding:2rem;max-width:1200px;margin:0 auto;line-height:1.7;}h1{color:#6366f1;}h2{color:#8b5cf6;border-bottom:2px solid #e5e7eb;padding-bottom:0.5rem;margin-top:2rem;}table{width:100%;border-collapse:collapse;margin:1rem 0;}th,td{border:1px solid #e5e7eb;padding:0.5rem;}th{background:#6366f1;color:white;}@media print{h2{page-break-before:always;}}</style></head><body>\${html}</body></html>\`;
fs.writeFileSync('monthly-temp.html', full);
(async () => {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.goto('file://' + process.cwd() + '/monthly-temp.html', { waitUntil: 'networkidle0', timeout: 60000 });
  await page.pdf({ path: '$REPORT_DIR/${MONTH}-total-review.pdf', format: 'A4', printBackground: true, margin: { top: '20mm', right: '15mm', bottom: '20mm', left: '15mm' } });
  await browser.close();
  fs.unlinkSync('monthly-temp.html');
  console.log('✅ PDF 已生成：$REPORT_DIR/${MONTH}-total-review.pdf');
})().catch(err => console.error('PDF 生成失败:', err.message));
" &

# 发送总结到飞书
REPORT=$(cat "$OUTPUT_DIR/${MONTH}-summary.md")
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$REPORT"
echo "✅ 月总结已发送（飞书） - $(date)"

wait
echo ""
echo "✅ 每月总结脚本创建完成"
