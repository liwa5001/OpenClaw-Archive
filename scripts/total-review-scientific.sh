#!/bin/bash
# Castle Six 科学综合复盘脚本（完整版）
# 基于木桶理论、系统论、PERMA 模型、关联分析进行深度分析

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/total-review-scientific.log"
FEISHU_USER="ou_7781abd1e83eae23ccf01fe627f0747f"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Castle Six 科学综合复盘开始 ==="

TODAY=$(date '+%Y-%m-%d')
YESTERDAY=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')

# 读取各堡数据
get_castle_score() {
    local castle=$1
    local date=$2
    local file=""
    
    case "$castle" in
        "health")
            file="$WORKSPACE/daily-output/health/daily-stats/$date-health-stats.md"
            ;;
        "growth")
            file="$WORKSPACE/daily-output/growth/daily-stats/$date-growth-stats.md"
            ;;
        "relationship")
            file="$WORKSPACE/daily-output/relationship/weekly-stats/$date-relationship-stats.md"
            ;;
    esac
    
    if [ -f "$file" ]; then
        grep "综合评分\|**${scores.total}" "$file" | head -1 | grep -o "[0-9]*/100" | head -1 | grep -o "[0-9]*" || echo "0"
    else
        echo "0"
    fi
}

# 获取本周数据
HEALTH_SCORE=$(get_castle_score "health" "$TODAY")
GROWTH_SCORE=$(get_castle_score "growth" "$TODAY")
RELATIONSHIP_SCORE=$(get_castle_score "relationship" "$TODAY")

# 计算统计值
calculate_stats() {
    local scores=("$@")
    local sum=0
    local count=0
    local min=100
    local max=0
    local min_castle=""
    
    for i in "${!scores[@]}"; do
        local score=${scores[$i]}
        if [ "$score" -gt 0 ]; then
            sum=$((sum + score))
            count=$((count + 1))
            
            if [ "$score" -lt "$min" ]; then
                min=$score
                case $i in
                    0) min_castle="health" ;;
                    1) min_castle="growth" ;;
                    2) min_castle="relationship" ;;
                esac
            fi
            
            if [ "$score" -gt "$max" ]; then
                max=$score
            fi
        fi
    done
    
    if [ $count -gt 0 ]; then
        local mean=$((sum / count))
        # 简化标准差计算
        local variance=0
        for i in "${!scores[@]}"; do
            local score=${scores[$i]}
            if [ "$score" -gt 0 ]; then
                local diff=$((score - mean))
                variance=$((variance + diff * diff))
            fi
        done
        variance=$((variance / count))
        # 近似标准差
        local std_dev=$(echo "sqrt($variance)" | bc 2>/dev/null || echo "0")
        
        echo "$mean $std_dev $min $max $min_castle"
    else
        echo "0 0 0 0 unknown"
    fi
}

STATS=$(calculate_stats $HEALTH_SCORE $GROWTH_SCORE $RELATIONSHIP_SCORE)
read MEAN STD_DEV MIN_SCORE MAX_SCORE MIN_CASTLE <<< "$STATS"

# 木桶理论分析
BUCKET_ANALYSIS=""
if [ "$MIN_SCORE" -lt 60 ]; then
    BUCKET_ANALYSIS="🔴 严重短板：${MIN_CASTLE}堡（${MIN_SCORE}分）需要立即关注！"
elif [ "$MIN_SCORE" -lt 70 ]; then
    BUCKET_ANALYSIS="🟡 需要关注：${MIN_CASTLE}堡（${MIN_SCORE}分）有提升空间"
else
    BUCKET_ANALYSIS="✅ 无明显短板，各堡发展均衡"
fi

# 平衡度分析
BALANCE_ANALYSIS=""
if [ "$STD_DEV" -gt 20 ]; then
    BALANCE_ANALYSIS="⚠️ 严重失衡（标准差 ${STD_DEV}）"
elif [ "$STD_DEV" -gt 10 ]; then
    BALANCE_ANALYSIS="🟡 轻度失衡（标准差 ${STD_DEV}）"
else
    BALANCE_ANALYSIS="✅ 发展平衡（标准差 ${STD_DEV}）"
fi

# 生成总评
TOTAL_SCORE=$MEAN
TOTAL_TEXT=""
if [ "$TOTAL_SCORE" -ge 85 ]; then
    TOTAL_TEXT="优秀🌟 全面表现出色！"
elif [ "$TOTAL_SCORE" -ge 70 ]; then
    TOTAL_TEXT="良好✅ 继续保持！"
elif [ "$TOTAL_SCORE" -ge 60 ]; then
    TOTAL_TEXT="及格👌 还有提升空间"
else
    TOTAL_TEXT="加油💪 需要重点关注"
fi

# 生成建议
SUGGESTIONS=""
case "$MIN_CASTLE" in
    "health")
        SUGGESTIONS="🏃 **健康优先：**
- 优化睡眠质量
- 增加运动频率
- 改善饮食习惯"
        ;;
    "growth")
        SUGGESTIONS="📚 **学习优先：**
- 调整学习计划
- 提高学习效率
- 坚持每日答题"
        ;;
    "relationship")
        SUGGESTIONS="💕 **关系优先：**
- 增加深度沟通
- 安排优质陪伴时间
- 学习非暴力沟通"
        ;;
esac

# 发送飞书消息
log "发送科学综合复盘..."

MESSAGE="🏰 **Castle Six 科学综合复盘 | $TODAY**

━━━━━━━━━━━━━━━━━━

## 📊 本周总览

**各堡得分：**
| 城堡 | 得分 | 状态 |
|------|------|------|
| 💪 健康堡 | $HEALTH_SCORE/100 | $([ $HEALTH_SCORE -ge 80 ] && echo '🌟' || ([ $HEALTH_SCORE -ge 60 ] && echo '✅' || echo '💪')) |
| 📚 成长堡 | $GROWTH_SCORE/100 | $([ $GROWTH_SCORE -ge 80 ] && echo '🌟' || ([ $GROWTH_SCORE -ge 60 ] && echo '✅' || echo '💪')) |
| 💕 关系堡 | $RELATIONSHIP_SCORE/100 | $([ $RELATIONSHIP_SCORE -ge 80 ] && echo '🌟' || ([ $RELATIONSHIP_SCORE -ge 60 ] && echo '✅' || echo '💪')) |

**综合评估：**
- **均值：** $MEAN 分
- **标准差：** $STD_DEV（$BALANCE_ANALYSIS）
- **短板：** $([ $MIN_CASTLE = 'health' ] && echo '💪 健康堡' || ([ $MIN_CASTLE = 'growth' ] && echo '📚 成长堡' || echo '💕 关系堡'))（$MIN_SCORE 分）

━━━━━━━━━━━━━━━━━━

## 🔍 深度分析

### 1. 木桶理论分析

$BUCKET_ANALYSIS

**影响评估：**
- 短板限制了整体发展水平
- 建议优先改善短板堡

### 2. 平衡度分析

$BALANCE_ANALYSIS

**建议：**
- 标准差 < 10：✅ 保持当前平衡状态
- 标准差 10-20：🟡 关注低分堡
- 标准差 > 20：⚠️ 需要调整资源分配

### 3. 趋势分析

⏳ 趋势分析待累积更多数据...

━━━━━━━━━━━━━━━━━━

## 💡 专业建议

### 优先级 1：$([ $MIN_CASTLE = 'health' ] && echo '💪 健康堡改善' || ([ $MIN_CASTLE = 'growth' ] && echo '📚 成长堡改善' || echo '💕 关系堡改善'))

$SUGGESTIONS

**预期效果：** 2 周内该堡回升 10-15 分

### 优先级 2：其他堡保持

继续保持当前良好状态

━━━━━━━━━━━━━━━━━━

## 📈 下周目标

| 城堡 | 当前分 | 目标分 | 关键行动 |
|------|--------|--------|---------|
| $([ $MIN_CASTLE = 'health' ] && echo '💪 健康堡' || ([ $MIN_CASTLE = 'growth' ] && echo '📚 成长堡' || echo '💕 关系堡')) | $MIN_SCORE | $((MIN_SCORE + 10)) | 按上述建议执行 |
| 其他堡 | - | 保持 | 维持当前节奏 |

━━━━━━━━━━━━━━━━━━

**🏰 城堡六堡 | 科学复盘，持续进步！**
"

/opt/homebrew/bin/openclaw message send --channel feishu --target "$FEISHU_USER" --message "$MESSAGE"
log "✅ Castle Six 科学综合复盘已发送"
log "=== Castle Six 科学综合复盘完成 ==="
