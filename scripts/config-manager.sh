#!/bin/bash
# 配置管理工具 - 查看和管理活跃配置
# 用法：./scripts/config-manager.sh [list|check|add|remove]

cd /Users/liwang/.openclaw/workspace

CONFIG_FILE="config/active-configs.json"

case "$1" in
  list|"")
    echo "📋 活跃配置列表"
    echo "================"
    echo ""
    
    if command -v jq &> /dev/null; then
      # 使用 jq 格式化输出
      jq -r '.tasks | to_entries[] | "\(.key): \(.value.name) [\(.value.status)]"' "$CONFIG_FILE"
    else
      # 没有 jq 时使用 grep
      echo "⚠️  未安装 jq，显示原始配置..."
      echo "配置文件：$CONFIG_FILE"
      echo ""
      grep -A2 '"name":' "$CONFIG_FILE" | head -20
    fi
    ;;
    
  check)
    echo "🔍 运行配置验证..."
    ./scripts/validate-configs.sh
    ;;
    
  add)
    echo "➕ 添加新配置"
    echo "请编辑配置文件：$CONFIG_FILE"
    echo "然后运行验证：./scripts/validate-configs.sh"
    ;;
    
  remove)
    echo "➖ 删除配置"
    echo "请在配置文件中将任务状态改为 'deprecated'"
    echo "配置文件：$CONFIG_FILE"
    ;;
    
  help|--help|-h)
    echo "配置管理工具"
    echo ""
    echo "用法：$0 [命令]"
    echo ""
    echo "命令:"
    echo "  list    列出所有活跃配置（默认）"
    echo "  check   运行配置验证"
    echo "  add     添加新配置"
    echo "  remove  删除/停用配置"
    echo "  help    显示此帮助信息"
    ;;
    
  *)
    echo "❌ 未知命令：$1"
    echo "运行 '$0 help' 查看帮助"
    exit 1
    ;;
esac
