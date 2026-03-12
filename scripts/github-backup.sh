#!/bin/bash
# OpenClaw 工作区自动备份到 GitHub
# 每周一凌晨 2 点执行

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/github-backup.log"
BACKUP_DIR="/Users/liwang/.openclaw/workspace/.backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== OpenClaw GitHub 备份开始 ==="

# 1. 检查 Git 状态
log "检查 Git 状态..."
cd "$WORKSPACE"

if ! git status > /dev/null 2>&1; then
    log "❌ 错误：当前目录不是 Git 仓库"
    exit 1
fi
log "✅ Git 仓库检查通过"

# 2. 创建备份目录
log "创建备份目录..."
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_LOG="$BACKUP_DIR/backup-$TIMESTAMP.log"

# 3. 获取当前分支
if git rev-parse HEAD > /dev/null 2>&1; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    log "当前分支：$BRANCH"
else
    BRANCH="main（新仓库）"
    log "当前分支：$BRANCH（仓库还没有提交）"
fi

# 4. 获取要备份的文件列表
log "扫描工作区文件..."
FILE_COUNT=$(find . -type f \
    -not -path "./.git/*" \
    -not -path "./.backup/*" \
    -not -path "./node_modules/*" \
    -not -path "./logs/*" \
    -not -name "*.log" \
    -not -name "*.bak" \
    -not -name "chat.db*" \
    | wc -l | tr -d ' ')

log "发现 $FILE_COUNT 个文件需要备份"

# 5. 检查 Git 状态（是否有未提交的文件）
if git rev-parse HEAD > /dev/null 2>&1; then
    UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
    if [ "$UNCOMMITTED" -gt 0 ]; then
        log "⚠️ 警告：有 $UNCOMMITTED 个未提交的文件"
        log "未提交文件列表："
        git status --porcelain | tee -a "$BACKUP_LOG"
    else
        log "✅ 所有文件已提交"
    fi
else
    UNCOMMITTED="未知"
    log "⚠️ 警告：仓库还没有提交，无法检查未提交文件"
fi

# 6. 获取远程仓库信息
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "未配置")
log "远程仓库：$REMOTE_URL"

# 7. 获取最新提交信息
if git rev-parse HEAD > /dev/null 2>&1; then
    LAST_COMMIT=$(git log -1 --pretty=format:"%h - %an - %ar : %s" 2>/dev/null || echo "无法获取")
    log "最新提交：$LAST_COMMIT"
else
    LAST_COMMIT="⚠️ 仓库还没有提交"
    log "⚠️ 警告：仓库还没有任何提交"
fi

# 8. 尝试推送（如果有更改）
log "检查是否需要推送..."

# 检查仓库是否有提交
if ! git rev-parse HEAD > /dev/null 2>&1; then
    log "⚠️ 警告：仓库还没有提交，需要先手动提交并推送"
    PUSH_STATUS="跳过（无提交）"
    LOCAL=""
    REMOTE=""
else
    git fetch origin > /dev/null 2>&1 || true
    
    # 检查本地和远程是否有差异
    LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
    
    if [ -z "$REMOTE" ]; then
        log "⚠️ 警告：没有配置上游分支，跳过推送"
        PUSH_STATUS="跳过（无上游分支）"
    elif [ "$LOCAL" = "$REMOTE" ]; then
        log "✅ 本地与远程同步，无需推送"
        PUSH_STATUS="已同步"
    else
        log "检测到差异，尝试推送..."
        if git push origin "$BRANCH" 2>&1 | tee -a "$BACKUP_LOG"; then
            log "✅ 推送成功"
            PUSH_STATUS="推送成功"
        else
            log "❌ 推送失败，可能需要手动处理"
            PUSH_STATUS="推送失败"
        fi
    fi
fi

# 9. 验证文件完整性
log "验证文件完整性..."
VERIFICATION_LOG="$BACKUP_DIR/verification-$TIMESTAMP.txt"

{
    echo "=== OpenClaw 文件验证报告 ==="
    echo "备份时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "分支：$BRANCH"
    echo "远程仓库：$REMOTE_URL"
    echo "最新提交：$LAST_COMMIT"
    echo "推送状态：$PUSH_STATUS"
    echo ""
    echo "=== 核心文件检查 ==="
    
    # 检查关键文件是否存在
    CRITICAL_FILES=(
        "scripts/castle-six-daily-questionnaire.sh"
        "health-form/index.html"
        "health-form/server.js"
        "growth-form/index.html"
        "growth-form/server.js"
        "relationship-form/index.html"
        "relationship-form/server.js"
        "quiz-form/index.html"
        "quiz-form/server.js"
        "agents/review-system/castle-six-status.md"
    )
    
    MISSING_FILES=0
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ $file"
        else
            echo "❌ $file (缺失)"
            MISSING_FILES=$((MISSING_FILES + 1))
        fi
    done
    
    echo ""
    echo "=== 文件统计 ==="
    echo "总文件数：$FILE_COUNT"
    echo "缺失关键文件：$MISSING_FILES"
    echo ""
    echo "=== Git 状态 ==="
    if git rev-parse HEAD > /dev/null 2>&1; then
        git status --short
    else
        echo "⚠️ 仓库还没有提交"
    fi
    echo ""
    echo "=== 验证完成 ==="
} > "$VERIFICATION_LOG"

log "验证报告已保存：$VERIFICATION_LOG"

# 10. 生成备份摘要
SUMMARY="$BACKUP_DIR/summary-$TIMESTAMP.md"
{
    echo "# OpenClaw 备份摘要"
    echo ""
    echo "**备份时间：** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**分支：** $BRANCH"
    echo "**远程仓库：** $REMOTE_URL"
    echo "**文件总数：** $FILE_COUNT"
    echo "**未提交文件：** $UNCOMMITTED"
    echo "**推送状态：** $PUSH_STATUS"
    echo "**最新提交：** $LAST_COMMIT"
    echo ""
    echo "**下次备份：** 下周一 02:00"
    echo ""
    echo "## 验证结果"
    echo ""
    if [ $MISSING_FILES -eq 0 ]; then
        echo "✅ 所有关键文件存在"
    else
        echo "❌ 缺失 $MISSING_FILES 个关键文件（见验证报告）"
    fi
    echo ""
    echo "## 详细报告"
    echo ""
    echo "- 验证报告：\`verification-$TIMESTAMP.txt\`"
    echo "- Git 状态：\`backup-$TIMESTAMP.log\`"
} > "$SUMMARY"

log "备份摘要已保存：$SUMMARY"

# 11. 发送通知
log "发送备份通知..."
MESSAGE="🗄️ **OpenClaw 备份完成 | $(date '+%Y-%m-%d')**

**备份时间：** $(date '+%H:%M:%S')
**分支：** $BRANCH
**文件总数：** $FILE_COUNT
**未提交文件：** $UNCOMMITTED
**推送状态：** $PUSH_STATUS

**验证结果：** $([ $MISSING_FILES -eq 0 ] && echo '✅ 所有关键文件存在' || echo '❌ 缺失 '$MISSING_FILES' 个文件')

**最新提交：**
\`\`\`
$LAST_COMMIT
\`\`\`

**详细报告：**
\`$SUMMARY\`

---
🏰 Castle Six | 自动备份系统
"

# 发送到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE" 2>&1 | tee -a "$BACKUP_LOG" || log "⚠️ 飞书通知发送失败"

log "=== OpenClaw GitHub 备份完成 ==="
log "备份摘要：$SUMMARY"

# 清理旧备份（保留最近 10 次）
log "清理旧备份..."
cd "$BACKUP_DIR"
ls -t summary-*.md | tail -n +11 | xargs -r rm
ls -t verification-*.txt | tail -n +11 | xargs -r rm
ls -t backup-*.log | tail -n +11 | xargs -r rm
log "✅ 旧备份已清理（保留最近 10 次）"

exit 0
