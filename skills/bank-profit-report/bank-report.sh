#!/bin/bash
# 银行理财收益跟踪技能 - 快捷启动脚本
# 使用方法：./bank-report.sh [选项]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查依赖
if ! command -v node &> /dev/null; then
    echo "❌ 错误：需要安装 Node.js"
    echo "🔗 下载地址：https://nodejs.org/"
    exit 1
fi

# 检查依赖包
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install
fi

# 传递参数给 Node.js 脚本
echo "🏦 启动银行理财收益跟踪技能..."
node scripts/generate-report.js "$@"

echo ""
echo "✅ 完成！"
