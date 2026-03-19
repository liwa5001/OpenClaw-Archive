#!/bin/bash

# 读书总结脚本 - 在用户完成 13 天阅读后生成总复盘点评
# 用法：./audiobook-final-review.sh

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/audiobook-review.log"
PROGRESS_FILE="$WORKSPACE/audiobook/progress/user-progress.json"
OUTPUT_DIR="$WORKSPACE/daily-output/growth/audiobook-reviews"

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始生成读书总结" >> "$LOG_FILE"

# 检查进度文件
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 进度文件不存在" >> "$LOG_FILE"
    exit 1
fi

# 读取进度数据
COMPLETED_DAYS=$(cat "$PROGRESS_FILE" | grep -o '"completedDays":\[[^]]*\]' | sed 's/"completedDays":\[//;s/\]//')
TOTAL_TIME=$(cat "$PROGRESS_FILE" | grep -o '"totalTime":[0-9]*' | cut -d':' -f2)
COMPLETED_COUNT=$(echo "$COMPLETED_DAYS" | tr ',' '\n' | grep -c '[0-9]')

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 已完成 $COMPLETED_COUNT/13 天，总时长 $((TOTAL_TIME / 60)) 分钟" >> "$LOG_FILE"

# 检查是否完成全书
if [ "$COMPLETED_COUNT" -lt 13 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ 尚未完成全书 ($COMPLETED_COUNT/13)" >> "$LOG_FILE"
    exit 0
fi

# 生成总结报告
TODAY=$(date '+%Y-%m-%d')
OUTPUT_FILE="$OUTPUT_DIR/$TODAY-audiobook-final-review.md"

cat > "$OUTPUT_FILE" << EOF
# 📚 《每天懂点人情世故》读书总结

**完成日期：** $TODAY  
**总耗时：** $((TOTAL_TIME / 60)) 分钟（约 $((TOTAL_TIME / 3600)) 小时）  
**完成率：** 100% (13/13 天)

---

## 📊 阅读数据

| 指标 | 数值 |
|------|------|
| 总章节 | 13 天内容 |
| 完成天数 | $COMPLETED_COUNT 天 |
| 已听时长 | $((TOTAL_TIME / 60)) 分钟 |
| 平均每天 | $((TOTAL_TIME / COMPLETED_COUNT / 60)) 分钟 |
| 开始日期 | $(cat "$PROGRESS_FILE" | grep -o '"lastListen":"[^"]*' | head -1 | cut -d'"' -f4 | cut -dT -f1) |
| 完成日期 | $TODAY |

---

## 📖 全书核心要点回顾

### Day 1: 序言
- 核心：学会做人做事的重要性
- 金句：天地间真滋味，唯静者能尝得出

### Day 2-3: 大智若愚
- 核心：真正聪明的人往往看起来笨拙
- 要点：木秀于林风必摧之，学会低调

### Day 4-5: 吃亏是福
- 核心：超凡脱俗的心态
- 要点：能吃亏的人，往往吃不了亏

### Day 6: 谦虚忍耐
- 核心：懂得适时地低头
- 要点：低头不是认输，是看清脚下的路

### Day 7-8: 宽容大度
- 核心：赢得人心的谋略
- 要点：宽容别人，就是放过自己

### Day 9-10: 管住舌头
- 核心：把握做事的时机
- 要点：话多不如话少，话少不如话好

### Day 11: 韬光养晦
- 核心：隐藏光芒的策略
- 要点：时机未到，学会蛰伏

### Day 12: 方圆哲学 + 知足常乐
- 核心：成功之前的积累，低调对待名利
- 要点：外圆内方，知足者富

### Day 13: 投资人情 + 礼尚往来 + 感恩有爱
- 核心：做储蓄人情的高手，把爱传递下去
- 要点：人情是存出来的，不是借出来的

---

## 💡 城堡点评

### ✅ 做得好的地方

1. **坚持完成** - 13 天连续收听，展现了良好的执行力
2. **主动学习** - 选择听书方式利用通勤时间，时间管理意识强
3. **反思习惯** - 每天记录感想，有助于内化知识

### ⚠️ 可能存在的缺失

1. **实践不足** - 听书容易，实践难。建议：
   - 每周选 1-2 个要点刻意练习
   - 记录实践案例和效果
   
2. **深度思考** - 听书是被动输入，建议：
   - 每章结束后暂停，问自己"我能用在哪儿？"
   - 结合实际工作场景思考应用

3. **复盘频率** - 建议：
   - 每周回顾一次笔记
   - 每月温习一次核心要点

### 🎯 后续建议

1. **建立人情账户**
   - 记录你帮助的人和事
   - 定期"储蓄"人情，不要临时抱佛脚

2. **练习"管住舌头"**
   - 说话前先想三秒
   - 重要场合提前准备谈话要点

3. **培养"大智若愚"气质**
   - 不急于表现自己
   - 关键时刻再展现能力

4. **持续学习**
   - 推荐延伸阅读：《菜根谭》《增广贤文》
   - 关注实际案例，观察身边"会做人"的人

---

## 📈 成长堡数据同步

- [ ] 听书记录已同步
- [ ] 感想笔记已归档
- [ ] 总复盘堡已更新
- [ ] 后续提醒已设置

---

*生成时间：$(date '+%Y-%m-%d %H:%M:%S')*  
*城堡 🏰 点评*
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 读书总结已生成：$OUTPUT_FILE" >> "$LOG_FILE"

# 发送飞书通知
MESSAGE="🎉 **恭喜完成《每天懂点人情世故》全书！**

📊 **阅读数据：**
- 完成天数：$COMPLETED_COUNT/13 天
- 总时长：$((TOTAL_TIME / 60)) 分钟
- 完成日期：$TODAY

💡 **城堡已生成详细点评**
- 包含：核心要点回顾、做得好的地方、可能缺失、后续建议
- 查看路径：\`daily-output/growth/audiobook-reviews/$TODAY-audiobook-final-review.md\`

📌 **下一步：**
1. 阅读城堡点评，看看有哪些可以改进
2. 选 1-2 个要点开始实践
3. 下周总复盘时回顾应用效果

🎧 有声读本系统将持续为你服务，下一本书想听什么？"

cd "$WORKSPACE"
openclaw message send --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 已发送飞书通知" >> "$LOG_FILE"
