#!/bin/bash
# Skill 安装记录脚本
# 用法：./log-skill.sh "skill 名（功能描述）"

set -e

TODAY=$(date +%Y-%m-%d)
SKILLS_LOG="/Users/liwang/.openclaw/workspace/logs/skills-${TODAY}.log"

if [ -z "$1" ]; then
  echo "用法：$0 \"skill 名（功能描述）\""
  exit 1
fi

echo "$1" >> "$SKILLS_LOG"
echo "✅ 已记录：$1"
