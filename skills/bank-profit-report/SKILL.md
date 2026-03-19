# 🏦 银行理财收益跟踪技能

**技能名称：** bank-profit-report  
**版本：** v1.0  
**创建时间：** 2026-03-15  
**维护者：** 城堡 🏰

---

## 📋 技能说明

自动生成上海地区银行理财收益跟踪 Excel 报表，包含：

- **银行分类**：国有银行、股份制商业银行、城市商业银行
- **期限分类**：现金类 (T+1)、3 个月、6 个月、12 个月
- **时间节点**：支持自定义多个时间节点
- **汇总统计**：各时间节点平均收益率对比、趋势分析
- **达标情况**：实际收益率与业绩基准对比

---

## 🚀 使用方法

### 基本用法

```bash
# 直接调用（生成当前月份报表）
openclaw skill run bank-profit-report
```

### 自定义时间节点

```bash
# 指定时间节点
openclaw skill run bank-profit-report --nodes "2026-01-31,2026-02-28,2026-03-31"
```

### 输出到指定目录

```bash
# 指定输出目录
openclaw skill run bank-profit-report --output "/path/to/output"
```

---

## 📁 文件结构

```
/workspace/skills/bank-profit-report/
├── SKILL.md                      # 技能说明文件
├── scripts/
│   └── generate-report.js        # 报表生成脚本
└── output/                       # 生成的 Excel 文件
    └── 上海银行理财收益跟踪 (汇总统计版)_YYYY-MM-DD.xlsx
```

---

## 🔧 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--nodes` | string | 自动计算最近 5 个月末 | 时间节点列表（逗号分隔） |
| `--output` | string | `/workspace/reports/wealth` | 输出目录 |
| `--banks` | string | 全部银行 | 银行类型（state/joint/city/all） |
| `--terms` | string | 全部期限 | 期限分类（cash/3m/6m/12m/all） |
| `--format` | string | xlsx | 输出格式（xlsx/csv） |

---

## 📊 输出内容

### Excel 工作表结构

| 序号 | 工作表 | 内容 |
|------|--------|------|
| 1-N | YYYY-MM-DD | 各时间节点详细数据 |
| N+1 | 📊 汇总统计 (截至最新) | 收益率趋势分析 |
| N+2 | 📋 数据说明 | 字段说明、达标标准 |

### 数据字段

| 字段 | 说明 |
|------|------|
| 银行类型 | 国有银行/股份制/城商行 |
| 排名 | 同类银行收益率排名 |
| 产品名称 | 理财产品全称 |
| 发行机构 | 银行名称 |
| 风险等级 | R1-R5 |
| 业绩基准/年化 | 前推对应期限的历史基准数据 |
| 基准说明 | 标注业绩基准时间来源 |
| 到期后业绩达标情况 | 实际收益率与业绩基准对比 |
| 实际收益率 | 产品到期后的真实收益率 |
| 期限分类 | 现金类/3 个月/6 个月/12 个月 |
| 具体期限 | 实际天数 |
| 起购金额 | 最低购买金额 |
| 购买渠道 | 销售渠道 |
| 产品登记编码 | 官方登记编码 |

---

## 💡 使用场景

### 1. 月末例行报告

```bash
# 每月最后一天运行
openclaw skill run bank-profit-report
```

### 2. 季度对比分析

```bash
# 生成季度报表
openclaw skill run bank-profit-report --nodes "2026-01-31,2026-02-28,2026-03-31"
```

### 3. 年度趋势分析

```bash
# 生成年度报表
openclaw skill run bank-profit-report --nodes "2025-12-31,2026-03-31,2026-06-30,2026-09-30,2026-12-31"
```

### 4. 特定银行对比

```bash
# 只对比股份制银行
openclaw skill run bank-profit-report --banks "joint"
```

---

## 🔗 相关资源

- **官方查询**：https://www.chinawealth.com.cn（中国理财网）
- **数据说明**：`/workspace/reports/wealth/数据收集指南.md`
- **使用文档**：`/workspace/reports/wealth/README.md`

---

## ⚠️ 重要提示

1. **数据来源**：当前为模拟数据，实际投资请查询官方渠道
2. **业绩基准**：不等于实际收益，理财非存款，投资需谨慎
3. **风险提示**：理财有风险，投资需谨慎
4. **验证方式**：www.chinawealth.com.cn 输入产品登记编码验证真伪

---

## 📝 更新日志

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| v1.0 | 2026-03-15 | 初始版本，支持银行分类、期限分类、汇总统计 |

---

## 🛠️ 技术实现

**核心脚本：** `scripts/generate-report.js`

**依赖：**
- Node.js >= 18.0.0
- exceljs >= 4.4.0

**安装依赖：**
```bash
cd /workspace/skills/bank-profit-report
npm install
```

---

## 📞 联系维护者

如有问题或建议，请联系：
- **维护者**：城堡 🏰
- **创建日期**：2026-03-15
