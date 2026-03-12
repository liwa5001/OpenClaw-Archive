#!/bin/bash
# 城堡六堡 - 每日 PDF 总结生成脚本

set -e

cd /Users/liwang/.openclaw/workspace

DATE=$(date +%Y-%m-%d)
PDF_DIR="project-log/daily-pdfs"
LOG_FILE="project-log/daily-summary-${DATE}.md"

echo "🏰 生成城堡六堡每日总结 | ${DATE}"
echo "================================"

# 创建总结文件
cat > "${LOG_FILE}" << EOF
# 🏰 城堡六堡 - 每日总结

**日期：** ${DATE}  
**生成时间：** $(date '+%Y-%m-%d %H:%M:%S')  
**版本：** v0.1

---

## 📋 今日项目进展

### 健康堡 (💪)
- [ ] 目标设定问卷
- [ ] 第一份日报生成
- [ ] 数据记录

### 其他堡
- 事业堡：📋 待开发
- 关系堡：📋 待开发
- 财富堡：📋 待开发
- 成长堡：📋 待开发
- 生活堡：📋 待开发

---

## 💬 重要对话记录

### 用户反馈
_(记录用户的重要反馈和建议)_

### 项目决策
_(记录今日的决策和变更)_

---

## 📊 数据更新

### 健康数据
- FTP 记录：____ W
- 体重记录：____ kg
- 睡眠记录：____ h

### Token 消耗
- 数据来源：从各脚本日志估算 / 无法获取
- 估算方法：根据调用次数 × 平均 token

---

## 🎯 明日计划

1. ____________________
2. ____________________
3. ____________________

---

## 📝 待办事项

- [ ] ____________________
- [ ] ____________________
- [ ] ____________________

---

**维护者：** 城堡 🏰
EOF

echo "✅ 总结已生成：${LOG_FILE}"

# 转换为 PDF（需要安装 markdown-pdf 或类似工具）
if command -v markdown-pdf &> /dev/null; then
    markdown-pdf -o "${PDF_DIR}/daily-summary-${DATE}.pdf" "${LOG_FILE}"
    echo "✅ PDF 已生成：${PDF_DIR}/daily-summary-${DATE}.pdf"
else
    echo "⚠️  markdown-pdf 未安装，仅生成 Markdown 文件"
    echo "   安装方法：npm install -g markdown-pdf"
fi

echo ""
echo "📁 文件位置："
echo "   Markdown: ${LOG_FILE}"
echo "   PDF: ${PDF_DIR}/daily-summary-${DATE}.pdf"
