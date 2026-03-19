#!/bin/bash
# 连夜压力测试 - 总控脚本
# 使用：./scripts/overnight-stress-test.sh

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd /Users/liwang/.openclaw/workspace

echo "🚨 连夜压力测试 - 总控脚本"
echo "========================================"
echo "开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ==================== 第 1 阶段：配置检查 ====================
echo "========================================"
echo "📋 第 1 阶段：配置持久化检查"
echo "========================================"

if ./scripts/validate-configs-persistent.sh; then
  echo ""
  echo "✅ 配置检查通过"
else
  echo ""
  echo "❌ 配置检查失败，请先修复配置问题"
  exit 1
fi

# ==================== 第 2 阶段：单轮测试 ====================
echo ""
echo "========================================"
echo "🔥 第 2 阶段：单轮全功能测试"
echo "========================================"

if ./scripts/stress-test-all.sh; then
  echo ""
  echo "✅ 单轮测试通过"
else
  echo ""
  echo "❌ 单轮测试失败，请检查日志"
  exit 1
fi

# ==================== 第 3 阶段：10 轮连续测试 ====================
echo ""
echo "========================================"
echo "🔁 第 3 阶段：10 轮连续压力测试"
echo "========================================"
echo "这将模拟 10 天的使用情况"
echo "每轮间隔 30 秒，预计耗时 10-15 分钟"
echo ""

read -p "按回车键开始 10 轮连续测试..." || true

if ./scripts/stress-test-10rounds.sh; then
  echo ""
  echo "✅ 10 轮连续测试通过"
else
  echo ""
  echo "❌ 10 轮连续测试失败，请检查日志"
  exit 1
fi

# ==================== 最终报告 ====================
echo ""
echo "========================================"
echo "🎉 连夜压力测试全部完成！"
echo "========================================"
echo "完成时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "📊 测试报告位置："
echo "   - 配置检查：logs/stress-test/"
echo "   - 单轮测试：logs/stress-test/stress-test-*.md"
echo "   - 10 轮测试：logs/stress-test/10rounds-*.md"
echo ""
echo "✅ 系统稳定性验证通过，可以投入使用！"

# 发送最终报告到飞书
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "🎉 连夜压力测试完成！

📊 测试阶段
━━━━━━━━━━━━━━━━━━
✅ 第 1 阶段：配置持久化检查
✅ 第 2 阶段：单轮全功能测试
✅ 第 3 阶段：10 轮连续压力测试

📄 测试报告
━━━━━━━━━━━━━━━━━━
位置：/workspace/logs/stress-test/

✅ 系统稳定性验证通过
可以投入使用！

🏰 城堡压力测试 | $(date '+%Y-%m-%d')"
