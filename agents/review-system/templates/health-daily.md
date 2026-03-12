---
type: daily
domain: health
date: {{DATE}}
agent: health-castle
template_version: v0.1
data_sources:
  - strava
  - memory/{{DATE}}.md
---

# 💪 健康堡日报 | {{DATE}}

**生成时间：** {{TIMESTAMP}}  
**数据完整度：** {{COMPLETENESS}}%

---

## 🏃 今日运动

{{#IF HAS_STRAVA_DATA}}
| 指标 | 数值 |
|------|------|
| 运动类型 | {{SPORT_TYPE}} |
| 距离 | {{DISTANCE}} km |
| 时长 | {{DURATION}} 分钟 |
| 平均心率 | {{AVG_HR}} bpm |
| 最大心率 | {{MAX_HR}} bpm |
| 平均功率 | {{AVG_WATTS}} W |
| 卡路里 | {{CALORIES}} kcal |

### 心率区间分析
- Z1 (恢复): {{Z1_PERCENT}}%
- Z2 (有氧): {{Z2_PERCENT}}% ← 目标区间
- Z3 (阈值): {{Z3_PERCENT}}%
- Z4 (无氧): {{Z4_PERCENT}}%
- Z5 (极限): {{Z5_PERCENT}}%

{{ELSE}}
⚠️ **今日无运动记录**

{{/IF}}

---

## 😴 睡眠质量

{{SLEEP_NOTES}}

---

## 🍽️ 饮食记录

{{FOOD_NOTES}}

---

## 📊 今日评分

| 维度 | 评分 | 说明 |
|------|------|------|
| 运动达标 | {{EXERCISE_SCORE}}/10 | {{EXERCISE_COMMENT}} |
| 睡眠质量 | {{SLEEP_SCORE}}/10 | {{SLEEP_COMMENT}} |
| 饮食健康 | {{FOOD_SCORE}}/10 | {{FOOD_COMMENT}} |
| **综合评分** | **{{TOTAL_SCORE}}/10** | {{TOTAL_COMMENT}} |

---

## 💡 明日建议

{{TOMORROW_TIPS}}

---

## 🔥 连续记录

- 连续运动：{{STREAK_DAYS}} 天
- 本月运动：{{MONTH_DAYS}} 天
- 最长连续：{{LONGEST_STREAK}} 天

---

🏰 城堡健康堡 | 科学训练，持续进步！💪
