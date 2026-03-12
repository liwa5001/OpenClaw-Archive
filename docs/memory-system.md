# 🧠 统一记忆系统

**创建时间：** 2026-03-07  
**维护者：** 城堡 🏰

---

## 📐 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                   统一记忆系统                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐         ┌──────────────┐            │
│  │ agent-memory │         │     QMD      │            │
│  │  结构化记忆   │         │   全文索引    │            │
│  ├──────────────┤         ├──────────────┤            │
│  │ • 事实 (20)   │         │ • 日志文件    │            │
│  │ • 经验 (3)    │         │ • 配置文档    │            │
│  │ • 实体 (1)    │         │ • Markdown   │            │
│  │ • 语义搜索    │         │ • BM25+ 向量  │            │
│  └──────────────┘         └──────────────┘            │
│         ↓                          ↓                   │
│  ~/.agent-memory/memory.db    ~/.cache/qmd/           │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          ↓
              ┌───────────────────────┐
              │    日志文件 (原始)     │
              │ ~/.openclaw/workspace │
              │    /logs/*.log        │
              └───────────────────────┘
```

---

## 🔧 工具说明

### 1. log-event.sh - 统一记录脚本

**位置：** `~/workspace/scripts/log-event.sh`

**用法：**
```bash
# 记录技能安装
./scripts/log-event.sh skill "Agent Reach" "搜索" "社交"

# 记录软件安装
./scripts/log-event.sh app "Node.js v22" "开发" "环境"

# 记录配置变更
./scripts/log-event.sh config "飞书 Webhook 配置" "消息" "同步"

# 记录错误
./scripts/log-event.sh error "API 超时" "网络" "天气"
```

**功能：**
- ✅ 写入日志文件（QMD 自动索引）
- ✅ 写入 agent-memory（结构化记忆）

---

### 2. search-memory.sh - 统一查询脚本

**位置：** `~/workspace/scripts/search-memory.sh`

**用法：**
```bash
# 搜索关键词
./scripts/search-memory.sh "技能安装"

# 查看记忆统计
./scripts/search-memory.sh
```

**输出：**
- 📦 agent-memory 结构化记忆
- 📚 QMD 全文索引结果
- 📄 相关日志文件

---

## 📊 当前状态

### agent-memory
- **事实：** 20 条
- **经验教训：** 3 条
- **实体：** 1 个

### QMD Collections
- **workspace:** 48 个 Markdown 文件
- **workspace-logs:** 13 个日志文件

---

## 💡 使用场景

### 场景 1：安装新技能
```bash
# 安装时记录
./scripts/log-event.sh skill "新技能名称" "分类" "标签"

# 日后查询
./scripts/search-memory.sh "技能"
```

### 场景 2：查找历史配置
```bash
# 搜索配置相关
./scripts/search-memory.sh "飞书配置"

# 或直接搜索日志
qmd search "webhook" -c workspace-logs
```

### 场景 3：回顾经验教训
```bash
cd ~/workspace/skills/agent-memory
uv run python -c "
from src.memory import AgentMemory
mem = AgentMemory()
lessons = mem.get_lessons()
for l in lessons:
    print(l)
"
```

---

## 🔄 自动化集成

### 每日小结自动读取
`daily-summary.sh` 已配置自动读取：
- `logs/skills-YYYY-MM-DD.log`
- `logs/installs-YYYY-MM-DD.log`

### cron 任务
```bash
# 每天 21:30 发送每日小结
30 21 * * * cd /Users/liwang/.openclaw/workspace && ./scripts/daily-summary.sh
```

---

## 📝 最佳实践

1. **及时记录** - 安装/配置时立即用 `log-event.sh` 记录
2. **标签规范** - 使用一致的标签便于搜索（如：技能、软件、配置、错误）
3. **定期清理** - QMD 会自动索引新日志，无需手动操作
4. **查询优先** - 遇到问题先搜索记忆系统，避免重复错误

---

## 🎯 未来扩展

- [ ] 自动记录 ClawHub 安装的技能
- [ ] 集成到 OpenClaw 工具调用钩子
- [ ] 定期向量嵌入更新 (`qmd embed`)
- [ ] 记忆过期自动清理

---

**城堡记忆系统 | 2026-03-07** 🏰
