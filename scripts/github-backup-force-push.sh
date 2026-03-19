#!/bin/bash
# OpenClaw GitHub 完整备份推送（一次性任务）
# 提交所有未提交的文件并推送到 GitHub

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/github-backup-force.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== OpenClaw GitHub 完整备份推送开始 ==="

cd "$WORKSPACE"

# 1. 检查 Git 状态
log "检查 Git 状态..."
if ! git status > /dev/null 2>&1; then
    log "❌ 错误：当前目录不是 Git 仓库"
    exit 1
fi

# 2. 获取未提交文件数量
UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
log "发现 $UNCOMMITTED 个未提交的文件"

if [ "$UNCOMMITTED" -eq 0 ]; then
    log "✅ 所有文件已提交，直接推送"
else
    # 3. 添加所有文件
    log "添加所有文件到暂存区..."
    git add -A
    log "✅ 已添加 $UNCOMMITTED 个文件"
    
    # 4. 提交
    COMMIT_MSG="backup: 完整备份 $(date '+%Y-%m-%d %H:%M') - 包含 $UNCOMMITTED 个文件"
    log "提交更改：$COMMIT_MSG"
    git commit -m "$COMMIT_MSG"
    log "✅ 提交成功"
fi

# 5. 推送到 GitHub
log "推送到 GitHub..."
git push origin main
log "✅ 推送成功"

# 6. 显示最新提交
log "最新提交记录："
git log -3 --oneline | tee -a "$LOG_FILE"

log "=== OpenClaw GitHub 完整备份推送完成 ==="

# 7. 发送通知到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "✅ GitHub 完整备份推送完成

📦 备份内容：
- 未提交文件：$UNCOMMITTED 个
- 提交信息：完整备份 $(date '+%Y-%m-%d %H:%M')
- 仓库：liwa5001/OpenClaw-Archive

📊 最新提交：
$(git log -3 --oneline)

🏰 城堡备份 | 自动推送" 2>/dev/null || log "⚠️ 飞书通知发送失败"
