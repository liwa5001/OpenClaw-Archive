#!/bin/bash
# Nano Banana Pro 图像生成脚本（带 V2RayX 代理）
# 用法：./nano-banana-gen.sh "提示词" [输出文件名]

set -e

# V2RayX 代理配置
export https_proxy="http://127.0.0.1:8001"
export http_proxy="http://127.0.0.1:8001"

# Gemini API Key
export GEMINI_API_KEY="AIzaSyCBMvVHaH3YxR7CippPzrDD0_RZKPR2Opo"

# 工作目录
WORKSPACE="/Users/liwang/.openclaw/workspace"
SKILL_PATH="$WORKSPACE/skills/nano-banana-pro/scripts/generate_image.py"

# 参数
PROMPT="${1:-a red apple}"
FILENAME="${2:-$(date +%Y-%m-%d-%H-%M-%S)-banana.png}"
RESOLUTION="${3:-1K}"

echo "🍌 Nano Banana Pro 图像生成"
echo "=============================="
echo "📝 提示词：$PROMPT"
echo "📁 输出：$FILENAME"
echo "📐 分辨率：$RESOLUTION"
echo "🌐 代理：http://127.0.0.1:8001"
echo "=============================="

cd "$WORKSPACE"

# 运行生成
uv run "$SKILL_PATH" \
  --prompt "$PROMPT" \
  --filename "$FILENAME" \
  --resolution "$RESOLUTION"

echo ""
echo "✅ 生成完成！"
echo "📂 文件位置：$(pwd)/$FILENAME"
