#!/bin/bash
# 健康堡每日复盘脚本 v3.0 (Castle Six - 表单版)
# 发送时间：每日 10:30
# 改进内容：
# 1. 发送 Web 表单链接（而非文字问卷）
# 2. 自动同步 Strava 运动数据
# 3. 用户提交后自动更新统计文件 + 飞书确认

set -e

cd /Users/liwang/.openclaw/workspace
# 超时设置
TIMEOUT_SECONDS=90


DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d)
STATS_DIR="daily-output/health/daily-stats"
ARCHIVE_DIR="daily-output/health/$(date +%Y-%m)"
mkdir -p "$STATS_DIR" "$ARCHIVE_DIR"

echo "💪 健康堡每日复盘 v3.0 (表单版) | $DATE"
echo "=========================================="

# ============================================
# 1. 获取 Strava 运动数据（昨日）
# ============================================
echo "📊 获取 $YESTERDAY 运动数据..."

EXERCISE_STATUS="😴 休息日"
EXERCISE_TYPE="-"
EXERCISE_DURATION="-"
EXERCISE_DISTANCE="-"
EXERCISE_MSG="昨天休息，恢复日也是训练的一部分！💪"

if [ -f "data/strava/latest-activities.json" ]; then
  # 使用 Node.js 解析 JSON 获取昨日数据
  ACTIVITY_DATA=$(node -e "
    const fs = require('fs');
    const activities = JSON.parse(fs.readFileSync('data/strava/latest-activities.json', 'utf8'));
    const yesterday = '$YESTERDAY';
    
    const yesterdayActivity = activities.find(act => {
      const startDate = act.start_date_local.split('T')[0];
      return startDate === yesterday;
    });
    
    if (yesterdayActivity) {
      const distanceKm = (yesterdayActivity.distance / 1000).toFixed(2);
      const timeMin = Math.round(yesterdayActivity.moving_time / 60);
      const type = yesterdayActivity.sport_type || yesterdayActivity.type;
      const name = yesterdayActivity.name;
      
      console.log(JSON.stringify({
        found: true,
        type: type,
        distance: distanceKm,
        time: timeMin,
        name: name
      }));
    } else {
      console.log(JSON.stringify({ found: false }));
    }
  " 2>/dev/null || echo '{"found":false}')
  
  if echo "$ACTIVITY_DATA" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); process.exit(d.found?0:1)" 2>/dev/null; then
    EXERCISE_STATUS="✅ 有记录"
    EXERCISE_TYPE=$(echo "$ACTIVITY_DATA" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).type)")
    EXERCISE_DURATION=$(echo "$ACTIVITY_DATA" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).time)")
    EXERCISE_DISTANCE=$(echo "$ACTIVITY_DATA" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).distance)")
    ACTIVITY_NAME=$(echo "$ACTIVITY_DATA" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).name)")
    EXERCISE_MSG="✅ $ACTIVITY_NAME (${EXERCISE_DISTANCE}km, ${EXERCISE_DURATION}分钟)"
  fi
fi

# ============================================
# 2. 生成统计文件（预填充 Strava 数据）
# ============================================
STATS_FILE="$STATS_DIR/${YESTERDAY}-health-stats.md"

cat > "$STATS_FILE" << EOF
---
type: health-daily-stats
date: $YESTERDAY
agent: health-castle
version: v3.0
data_sources:
  - strava: data/strava/latest-activities.json
  - 用户问卷：待填写
---

# 📊 健康堡每日统计 | $YESTERDAY

**生成时间：** $(date '+%Y-%m-%d %H:%M:%S')  
**数据完整度：** 运动✅ | 睡眠⏳ | 饮食⏳  
**状态：** 📝 等待用户填写表单

---

## 🏃 今日运动（Strava 自动同步）

$EXERCISE_MSG

| 指标 | 数值 | 单位 |
|------|------|------|
| 训练状态 | $EXERCISE_STATUS | - |
| 运动类型 | $EXERCISE_TYPE | - |
| 运动时长 | $EXERCISE_DURATION | 分钟 |
| 运动距离 | $EXERCISE_DISTANCE | km |

---

## 🍽️ 饮食记录

⏳ 等待用户填写表单...

---

## 😴 睡眠质量

⏳ 等待用户填写表单...

---

## ⚖️ 体重追踪

⏳ 等待用户填写表单...

---

## 📊 今日评分

⏳ 等待数据计算...

---

🏰 城堡健康堡 | 科学训练，持续进步！💪
EOF

echo "✅ 统计文件已生成：$STATS_FILE"

# ============================================
# 3. 生成归档文件
# ============================================
ARCHIVE_FILE="$ARCHIVE_DIR/${YESTERDAY}.md"

cat > "$ARCHIVE_FILE" << EOF
---
type: daily
domain: health
date: $YESTERDAY
agent: health-castle
template_version: v3.0
data_sources:
  - strava: data/strava/latest-activities.json
  - stats: $STATS_FILE
---

# 💪 健康堡日报 | $YESTERDAY

**生成时间：** $(date '+%Y-%m-%d %H:%M:%S')

---

## 🏃 今日运动

$EXERCISE_MSG

---

## 😴 睡眠

⏳ 等待表单填写...

---

## 🍽️ 饮食

⏳ 等待表单填写...

---

🏰 城堡健康堡 | 科学训练，持续进步！💪
EOF

echo "✅ 归档文件已生成：$ARCHIVE_FILE"

# ============================================
# 4. 获取表单链接（优先使用公网链接）
# ============================================
PUBLIC_URL_FILE="logs/health-public-url.txt"
if [ -f "$PUBLIC_URL_FILE" ]; then
    FORM_URL=$(cat "$PUBLIC_URL_FILE")
    echo "🌐 使用公网链接：$FORM_URL"
else
    # 使用 Node.js 获取 IP（跨平台兼容）
    LOCAL_IP=$(node -e "
    const os = require('os');
    const interfaces = os.networkInterfaces();
    let ip = 'localhost';
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                ip = iface.address;
                break;
            }
        }
        if (ip !== 'localhost') break;
    }
    console.log(ip);
    ")
    FORM_URL="http://${LOCAL_IP}:8893/"
    echo "🏠 使用内网链接：$FORM_URL"
fi

# ============================================
# 5. 发送飞书消息（含表单链接）
# ============================================
WEEKDAY=$(date -v-1d +%u)
case $WEEKDAY in
  1) TRAIN_PLAN="基础耐力骑行 30km Z2" ;;
  2) TRAIN_PLAN="恢复骑行 20km Z1" ;;
  3) TRAIN_PLAN="基础耐力骑行 30km Z2" ;;
  4) TRAIN_PLAN="休息日" ;;
  5) TRAIN_PLAN="基础耐力骑行 30km Z2" ;;
  6) TRAIN_PLAN="长距离骑行 40km Z2" ;;
  0) TRAIN_PLAN="主动恢复/休息" ;;
esac

cat > /tmp/health-form-invite.txt << INVITE
💪 健康堡每日问卷 | $YESTERDAY
═══════════════════════════

一天辛苦了！花 1 分钟填写今天的健康数据~

👉 **点击填写表单：**
$FORM_URL

【自动同步】
🏃 Strava 运动数据：$EXERCISE_MSG

【填写内容】
- 运动训练（已自动同步 Strava）
- 饮食记录（早/午/晚餐）
- 睡眠质量（入睡/起床/深睡/心率）
- 体重记录（仅周一填写）

【提交后】
✅ 数据自动保存到健康档案
✅ 立即收到评分和建议
✅ 生成明日训练计划

═══════════════════════════
💡 今日训练计划：$TRAIN_PLAN

🏰 城堡健康堡 | 数据驱动，持续进步！
INVITE

INVITE_TEXT=$(cat /tmp/health-form-invite.txt)
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$INVITE_TEXT"
echo "✅ 表单链接已发送（飞书） - $(date)"

# 清理临时文件
rm -f /tmp/health-form-invite.txt

echo ""
echo "=========================================="
echo "✅ 健康堡每日复盘 v3.0 (表单版) 完成！"
echo "   - 统计文件：$STATS_FILE ✅"
echo "   - 归档文件：$ARCHIVE_FILE ✅"
echo "   - 表单链接：$FORM_URL ✅"
echo "   - 飞书消息已发送 ✅"
echo "   - 等待用户填写表单 ⏳"
echo "=========================================="
echo ""
echo "📝 用户操作流程："
echo "   1. 点击飞书消息中的链接"
echo "   2. 填写健康数据表单"
echo "   3. 提交后自动保存 + 发送确认"
echo ""
