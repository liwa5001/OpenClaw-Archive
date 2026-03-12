# 🏰 Castle Six 剩余四堡开发计划

**创建日期：** 2026-03-12  
**状态：** 规划中  
**优先级：** 中

---

## 📊 当前进度

| 堡名 | 状态 | 完成度 | 说明 |
|------|------|--------|------|
| 💪 健康堡 | ✅ 完成 | 100% | HTML 表单 + 服务器 + cron |
| 📚 成长堡 | ✅ 完成 | 100% | HTML 表单 + 服务器 + cron |
| 💼 事业堡 | ⏳ 待开发 | 0% | - |
| 💕 关系堡 | ⏳ 待开发 | 0% | - |
| 💰 财富堡 | ⏳ 待开发 | 0% | - |
| 🎮 生活堡 | ⏳ 待开发 | 0% | - |
| 🏰 总复盘堡 | ✅ v2.0 完成 | 100% | 每日/每周/每月 |

**总体进度：** 3/7 (43%)

---

## 🎯 剩余四堡功能规划

### 1. 💼 事业堡 (Career Castle)

**目标：** 追踪工作/事业进展

**表单字段：**
- 📋 今日工作任务（3 项重点）
- ✅ 完成情况（已完成/进行中/未开始）
- 💡 工作亮点/成就
- 🤔 遇到的问题/挑战
- 📈 技能提升（学习/应用）
- 🤝 重要沟通/会议
- ⏰ 工作时长/效率自评

**数据保存：**
```
daily-output/career/daily-stats/YYYY-MM-DD-career-stats.md
```

**服务器端口：** 8898

**发送时间：** 每天 20:00（晚上下班后）

---

### 2. 💕 关系堡 (Relationship Castle)

**目标：** 维护重要人际关系

**表单字段：**
- 👨‍👩‍👦 家人互动（通话/见面/礼物）
- 👫 朋友联系（聊天/聚会）
- 💑 伴侣时光（如有）
- 🤝 社交活动
- 💝 为他人做的事
- 📞 主动联系的人数
- 😊 关系质量自评

**数据保存：**
```
daily-output/relationship/daily-stats/YYYY-MM-DD-relationship-stats.md
```

**服务器端口：** 8899

**发送时间：** 每天 21:00

---

### 3. 💰 财富堡 (Wealth Castle)

**目标：** 追踪财务状况

**表单字段：**
- 💵 今日收入（金额 + 来源）
- 💸 今日支出（分类：餐饮/交通/购物/娱乐/其他）
- 📊 支出分类统计
- 💳 信用卡/花呗使用
- 📈 投资账户变化（可选）
- 💡 理财学习/操作
- 🎯 月度预算进度

**数据保存：**
```
daily-output/wealth/daily-stats/YYYY-MM-DD-wealth-stats.md
```

**服务器端口：** 8900

**发送时间：** 每天 22:00

---

### 4. 🎮 生活堡 (Life Castle)

**目标：** 记录生活乐趣和平衡

**表单字段：**
- 😊 今日心情（1-10 分）
- 🎉 开心时刻/小确幸
- 🎨 娱乐活动（电影/音乐/游戏/阅读）
- 🧘 放松/冥想
- 🏠 家务/整理
- 🌱 个人爱好时间
- 😴 压力水平（1-5 分）
- 💭 感恩的 3 件事

**数据保存：**
```
daily-output/life/daily-stats/YYYY-MM-DD-life-stats.md
```

**服务器端口：** 8901

**发送时间：** 每天 21:30

---

## 📋 开发优先级

### 阶段一：核心三堡（已完成 ✅）
- [x] 健康堡
- [x] 成长堡
- [x] 总复盘堡

### 阶段二：生活三堡（建议顺序）
1. **💰 财富堡** - 财务数据重要且客观
2. **🎮 生活堡** - 心情/感恩记录简单
3. **💕 关系堡** - 需要定义关系网络

### 阶段三：事业堡
- **💼 事业堡** - 可能需要与工作工具集成

---

## 🔧 技术复用

所有新堡可以复用现有代码结构：

### 文件结构
```
castle-name-form/
├── index.html      # 表单页面（复制 + 修改字段）
└── server.js       # 服务器（复制 + 修改端口和路径）
```

### 脚本结构
```bash
scripts/
├── castle-six-daily-questionnaire.sh    # 健康 + 成长（已存在）
├── send-career-form.sh                  # 事业堡发送
├── send-relationship-form.sh            # 关系堡发送
├── send-wealth-form.sh                  # 财富堡发送
└── send-life-form.sh                    # 生活堡发送
```

### Cron 配置
```bash
# 财富堡 - 每天 22:00
0 22 * * * ./scripts/send-wealth-form.sh

# 生活堡 - 每天 21:30
30 21 * * * ./scripts/send-life-form.sh

# 关系堡 - 每天 21:00
0 21 * * * ./scripts/send-relationship-form.sh

# 事业堡 - 每天 20:00
0 20 * * * ./scripts/send-career-form.sh
```

---

## 📁 目录结构规划

```
/Users/liwang/.openclaw/workspace/
├── health-form/              ✅ 已存在
├── growth-form/              ✅ 已存在
├── career-form/              ⏳ 待创建
├── relationship-form/        ⏳ 待创建
├── wealth-form/              ⏳ 待创建
├── life-form/                ⏳ 待创建
│
├── daily-output/
│   ├── health/               ✅ 已存在
│   ├── growth/               ✅ 已存在
│   ├── career/               ⏳ 待创建
│   ├── relationship/         ⏳ 待创建
│   ├── wealth/               ⏳ 待创建
│   └── life/                 ⏳ 待创建
│
└── scripts/
    ├── castle-six-daily-questionnaire.sh  ✅ 已存在
    ├── send-career-form.sh                ⏳ 待创建
    ├── send-relationship-form.sh          ⏳ 待创建
    ├── send-wealth-form.sh                ⏳ 待创建
    └── send-life-form.sh                  ⏳ 待创建
```

---

## 🎯 下一步行动

### 立即可做（用户确认需求后）

1. **选择优先级最高的堡** - 建议从财富堡或生活堡开始
2. **复制模板代码** - 基于健康堡/成长堡快速创建
3. **自定义字段** - 根据上述规划调整表单
4. **配置 cron** - 设置合适的发送时间
5. **测试验证** - 确保表单提交和数据保存正常

### 预估工作量

| 堡名 | 预估时间 | 复杂度 |
|------|---------|--------|
| 财富堡 | 1-2 小时 | ⭐⭐ 中等（需要支出分类） |
| 生活堡 | 1 小时 | ⭐ 简单 |
| 关系堡 | 1-2 小时 | ⭐⭐ 中等（需要定义关系人） |
| 事业堡 | 2-3 小时 | ⭐⭐⭐ 较复杂（可能需要集成） |

---

## 💡 改进建议

### 统一服务器（可选优化）

当前方案：每个堡一个独立服务器（8897-8901）

**优化方案：** 创建统一的 Castle Six 服务器
```
端口：8890
路由：
- /health → 健康堡表单
- /growth → 成长堡表单
- /career → 事业堡表单
- /relationship → 关系堡表单
- /wealth → 财富堡表单
- /life → 生活堡表单
```

**优点：**
- 只需管理一个服务器
- 统一的日志和错误处理
- 更容易添加新功能（如统一仪表盘）

**缺点：**
- 代码重构需要时间
- 单点故障风险

---

## 📝 重要决策记录

### 2026-03-12：HTML 表单自动发送配置

**问题：** 创建了 HTML 表单但没有配置每日自动发送

**解决方案：**
1. 创建 `scripts/castle-six-daily-questionnaire.sh` 统一脚本
2. 配置 cron 任务（每天 8:00 AM）
3. 更新 HEARTBEAT.md 和 SOUL.md

**教训：**
- 自动化系统必须完整配置（脚本 + cron + 文档）
- 每次创建新系统都要更新 HEARTBEAT.md
- 重要教训要写入 SOUL.md 确保不忘

---

## 🔗 相关文件

- 健康堡表单：`health-form/index.html`
- 成长堡表单：`growth-form/index.html`
- 统一发送脚本：`scripts/castle-six-daily-questionnaire.sh`
- 配置文档：`HEARTBEAT.md`
- 教训记录：`SOUL.md`
- 对话日志：`agents/review-system/project-log/2026-03-12-castle6-daily.md`

---

**维护者：** 城堡 🏰  
**最后更新：** 2026-03-12  
**下次更新：** 开发下一个堡时

---

**🏰 Castle Six | 七堡合一，全面复盘！**
