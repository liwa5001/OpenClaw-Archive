#!/bin/bash
# 软件安装记录脚本
# 用法：./log-install.sh "软件名（描述）"

set -e

TODAY=$(date +%Y-%m-%d)
INSTALL_LOG="/Users/liwang/.openclaw/workspace/logs/installs-${TODAY}.log"

if [ -z "$1" ]; then
  echo "用法：$0 \"软件名（描述）\""
  exit 1
fi

echo "$1" >> "$INSTALL_LOG"
echo "✅ 已记录：$1"
