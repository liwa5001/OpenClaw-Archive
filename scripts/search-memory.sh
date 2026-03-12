#!/bin/bash
# 统一记忆查询脚本
# 用途：查询 agent-memory 和 QMD 中的记录

cd /Users/liwang/.openclaw/workspace

QUERY="$*"

if [ -z "$QUERY" ]; then
    echo "用法：$0 <搜索关键词>"
    echo "示例：$0 技能安装"
    echo ""
    echo "📊 记忆统计:"
    cd /Users/liwang/.openclaw/workspace/skills/agent-memory
    uv run python -c "from src.memory import AgentMemory; mem = AgentMemory(); print(mem.stats())" 2>/dev/null
    exit 0
fi

echo "🔍 搜索：$QUERY"
echo ""

echo "📦 agent-memory (结构化记忆):"
cd /Users/liwang/.openclaw/workspace/skills/agent-memory
uv run python -c "
from src.memory import AgentMemory
mem = AgentMemory()
facts = mem.recall('$QUERY')
if facts:
    for f in facts[:10]:
        print(f'  - {f}')
else:
    print('  (无匹配记忆)')
" 2>/dev/null
echo ""

echo "📚 QMD (全文索引):"
cd /Users/liwang/.openclaw/workspace
qmd search "$QUERY" -c workspace-logs 2>&1 | grep -E "^qmd://|Title:|Score:" | head -20
echo ""

echo "📄 相关日志文件:"
grep -l "$QUERY" ~/.openclaw/workspace/logs/*.log 2>/dev/null | head -5 | while read f; do
    echo "  - $f"
    tail -3 "$f" | sed 's/^/    /'
done
