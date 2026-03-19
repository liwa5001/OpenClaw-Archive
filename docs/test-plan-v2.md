# 🚨 六堡系统全面测试计划 v2.0

**版本：** 2.0  
**日期：** 2026-03-19  
**目标：** 全面测试所有六堡任务的稳定性和边界情况

---

## 📊 测试范围

### 核心任务清单

| 编号 | 任务名称 | Cron 时间 | 脚本 | 优先级 |
|------|---------|---------|------|--------|
| T01 | 每日晨报 | 07:00 | `morning-news.sh` | P0 |
| T02 | 每日爆款日报 | 07:30 | `daily-hot-report-ultimate.sh` | P0 |
| T03 | Castle Six 问卷 | 08:00 | `castle-six-daily-questionnaire.sh` | P0 |
| T04 | 健康堡每日复盘 | 10:30 | `health-daily-review.sh` | P1 |
| T05 | 成长堡每日复盘 | 21:00 | `growth-daily-review.sh` | P1 |
| T06 | 总复盘堡每日简报 | 21:45 | `total-daily-brief.sh` | P1 |
| T07 | 财富堡每周复盘 | 周日 20:00 | `wealth-weekly-check.sh` | P2 |
| T08 | 关系堡每周问卷 | 周日 20:00 | `relationship-weekly-sender.sh` | P2 |
| T09 | OpenClaw Gateway 重启 | 04:00 | 系统命令 | P1 |
| T10 | Strava 数据同步 | 每小时 | `sync-strava-data.sh` | P2 |

---

## 🔍 测试维度

### 维度 1：功能正确性

**测试内容：**
- ✅ 任务是否按时触发
- ✅ 脚本是否成功执行
- ✅ 消息是否成功发送
- ✅ 数据是否正确保存

**验证方法：**
- 检查 cron 执行日志
- 检查脚本输出日志
- 检查飞书消息记录
- 检查数据文件完整性

---

### 维度 2：边界情况（Corner Cases）

#### CC-01: 网络异常

**场景：**
- 新闻源网站不可达
- 飞书 API 超时
- 公网穿透服务断开

**预期：**
- 任务不崩溃，有错误日志
- 有重试机制或降级方案
- 发送失败通知

**测试方法：**
```bash
# 模拟网络超时
curl --max-time 1 https://www.thepaper.cn/

# 检查错误处理
grep -i "timeout\|error\|failed" logs/morning-news.log
```

---

#### CC-02: 服务器未启动

**场景：**
- 健康堡服务器未运行
- 成长堡服务器未运行
- 考题服务器未运行

**预期：**
- 脚本自动启动服务器
- 或发送错误通知
- 不阻塞其他任务

**测试方法：**
```bash
# 停止所有服务器
pkill -f "node server.js"

# 运行问卷脚本
./scripts/castle-six-daily-questionnaire.sh

# 检查服务器是否自动启动
curl http://localhost:8897/status
curl http://localhost:8896/status
```

---

#### CC-03: 日志文件过大

**场景：**
- 日志文件超过 100MB
- 磁盘空间不足
- 日志轮转失败

**预期：**
- 脚本不崩溃
- 有日志清理机制
- 或发送警告

**测试方法：**
```bash
# 检查日志大小
ls -lh logs/*.log | sort -k5 -h | tail -5

# 检查是否有清理机制
grep -r "log.*rotate\|cleanup\|truncate" scripts/*.sh
```

---

#### CC-04: 并发冲突

**场景：**
- 7:00 晨报和 7:05 成长堡计划同时运行
- 多个任务同时写同一文件
- Gateway 连接数超限

**预期：**
- 任务队列执行
- 文件锁机制
- 连接池管理

**测试方法：**
```bash
# 同时运行多个任务
./scripts/morning-news.sh &
./scripts/castle-six-daily-questionnaire.sh &
wait

# 检查是否有冲突
grep -i "lock\|conflict\|race" logs/*.log
```

---

#### CC-05: 数据格式异常

**场景：**
- Strava API 返回空数据
- 新闻源 HTML 结构变化
- 飞书消息格式错误

**预期：**
- 有数据验证
- 有默认值处理
- 有格式校验

**测试方法：**
```bash
# 检查数据验证
grep -r "if.*empty\|if.*null\|validate" scripts/*.sh

# 检查默认值
grep -r "default\|fallback\|||" scripts/*.sh
```

---

#### CC-06: 时间边界

**场景：**
- 跨天执行（23:55 开始，00:05 结束）
- 闰秒/时区变化
- 夏令时调整

**预期：**
- 日期计算正确
- 时区处理正确
- 不重复/不遗漏

**测试方法：**
```bash
# 检查时区设置
grep -r "TZ\|Asia/Shanghai" scripts/*.sh

# 检查日期计算
grep -r "date.*-v\|yesterday\|tomorrow" scripts/*.sh
```

---

#### CC-07: 资源泄漏

**场景：**
- 后台进程未清理
- 临时文件未删除
- 连接未关闭

**预期：**
- 有 cleanup 机制
- 临时文件定期清理
- 连接超时设置

**测试方法：**
```bash
# 检查后台进程
ps aux | grep "node\|sleep\|curl" | grep -v grep

# 检查临时文件
ls -lh /tmp/*morning* /tmp/*hot* 2>/dev/null

# 检查 cleanup
grep -r "trap\|cleanup\|rm -f" scripts/*.sh
```

---

#### CC-08: 配置变更

**场景：**
- HEARTBEAT.md 更新后未重启
- cron 表达式修改后未生效
- 飞书目标 ID 变更

**预期：**
- 配置热加载
- 或提示重启
- 配置验证机制

**测试方法：**
```bash
# 检查配置验证
./scripts/validate-configs-persistent.sh

# 检查配置加载
grep -r "HEARTBEAT\|config" scripts/*.sh
```

---

### 维度 3：性能测试

**指标：**
- 单次任务执行时间
- 平均响应时间
- 资源占用（CPU/内存）

**方法：**
```bash
# 记录执行时间
time ./scripts/morning-news.sh

# 监控资源
top -pid $(pgrep -f morning-news) 10
```

---

### 维度 4：恢复测试

**场景：**
- 任务失败后是否自动重试
- 失败后是否有通知
- 手动修复后是否正常

**方法：**
```bash
# 模拟失败
mv scripts/morning-news.sh scripts/morning-news.sh.bak
# 等待 cron 执行
# 检查是否有失败通知
mv scripts/morning-news.sh.bak scripts/morning-news.sh
# 检查是否恢复正常
```

---

## 📝 测试执行计划

### 第 1 阶段：单任务测试（今晚）

**时间：** 2026-03-19 00:20 - 02:00  
**内容：** 逐个测试每个任务

```bash
# 1. 晨报
./scripts/test-single-task.sh T01

# 2. 爆款日报
./scripts/test-single-task.sh T02

# 3. Castle Six 问卷
./scripts/test-single-task.sh T03

# ... 以此类推
```

---

### 第 2 阶段：边界情况测试（明晚）

**时间：** 2026-03-20 22:00 - 04:00  
**内容：** 模拟各种异常情况

```bash
# CC-01: 网络异常
./scripts/test-corner-case.sh CC-01

# CC-02: 服务器未启动
./scripts/test-corner-case.sh CC-02

# ... 以此类推
```

---

### 第 3 阶段：并发测试（周末）

**时间：** 2026-03-22 07:00 - 09:00  
**内容：** 模拟真实并发场景

```bash
# 同时触发多个任务
./scripts/test-concurrent.sh
```

---

### 第 4 阶段：长期稳定性（7 天）

**时间：** 2026-03-19 - 2026-03-25  
**内容：** 生产环境监控

```bash
# 每天自动运行监控
./scripts/production-monitor.sh
```

---

## 📊 测试报告模板

### 执行摘要

| 指标 | 数值 | 目标 | 状态 |
|------|------|------|------|
| 总测试数 | - | - | - |
| 通过数 | - | - | - |
| 失败数 | - | 0 | - |
| 通过率 | - | ≥95% | - |

### 任务详情

#### T01: 每日晨报

| 测试项 | 预期 | 实际 | 状态 |
|--------|------|------|------|
| 按时触发 | 07:00 | - | - |
| 执行成功 | 退出码 0 | - | - |
| 消息发送 | 飞书收到 | - | - |
| 数据保存 | memory/日期.md | - | - |
| CC-01 网络异常 | 有错误处理 | - | - |
| CC-07 资源泄漏 | 无泄漏 | - | - |

...（每个任务一个表格）

---

### 发现的问题

| 编号 | 问题描述 | 严重性 | 状态 |
|------|---------|--------|------|
| BUG-001 | - | P0/P1/P2 | 待修复/修复中/已修复 |

---

### 改进建议

| 编号 | 建议 | 优先级 | 预计工作量 |
|------|------|--------|-----------|
| IMP-001 | - | P0/P1/P2 | 1h/4h/1d |

---

## 🚀 立即执行

**今晚（2026-03-19）测试计划：**

1. **暂停 Gateway 重启任务**（避免干扰）
2. **单任务逐个测试**（T01-T06）
3. **记录详细日志**
4. **生成测试报告**

**命令：**
```bash
cd /Users/liwang/.openclaw/workspace
./scripts/full-system-test.sh --tonight
```

---

🏰 城堡测试计划 v2.0 | 2026-03-19
