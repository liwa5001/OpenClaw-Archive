#!/bin/bash

# picture-generation.sh - 商单生图主脚本

set -e

WORKSPACE="/Users/liwang/.openclaw/workspace"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建今日工作目录
mkdir -p "$WORKSPACE/picture-generation/input/$DATE"
mkdir -p "$WORKSPACE/picture-generation/prompts/$DATE"
mkdir -p "$WORKSPACE/picture-generation/generated/$DATE"
mkdir -p "$WORKSPACE/picture-generation/final/$DATE"

echo "🏰 商单生图流程启动 - $DATE"
echo "================================"
echo ""
echo "📁 工作目录："
echo "   输入：$WORKSPACE/picture-generation/input/$DATE"
echo "   提示词：$WORKSPACE/picture-generation/prompts/$DATE"
echo "   生成：$WORKSPACE/picture-generation/generated/$DATE"
echo "   最终：$WORKSPACE/picture-generation/final/$DATE"
echo ""

# 第一步：接收需求
echo "📋 第一步：请提供客户需求文字和效果图"
echo "   - 将效果图保存到：$WORKSPACE/picture-generation/input/$DATE/"
echo "   - 客户需求文字直接发送给我"
echo ""
echo "⏳ 等待用户提供素材..."
echo ""

# 等待用户确认素材已准备好
read -p "✅ 素材准备好了吗？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消"
    exit 1
fi

echo ""
echo "✅ 开始第二步：生成 AI 提示词..."
echo "🔗 工具：https://ai-edu.aigcfun.com/chat-tool/chat"
echo ""

# 调用浏览器工具打开网站
open "https://ai-edu.aigcfun.com/chat-tool/chat"

echo ""
echo "📝 请按以下步骤操作："
echo "   1. 选择【高阶模型】"
echo "   2. 输入提示词（拆解图片）："
echo ""
echo "   --- 提示词开始 ---"
echo "   详细拆解这张图片需要从主体内容，场景设定，风格参考，色调，色彩，构图，视角，细节补充这些角度，"
echo "   再用文字描述图片并汇总成一个能够用于 AI 作图工具文生图的提示词和英文提示词。"
echo "   要求成品图满足以下要求：[在此粘贴客户需求]"
echo "   --- 提示词结束 ---"
echo ""
echo "   3. 上传效果图"
echo "   4. 等待生成中文 AI 提示词（可能有 1-3 种）"
echo ""

read -p "✅ 提示词生成完毕，是否继续？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消"
    exit 1
fi

echo ""
echo "💾 请将生成的提示词保存到：$WORKSPACE/picture-generation/prompts/$DATE/prompts-$TIMESTAMP.md"
echo ""

read -p "✅ 提示词已保存，是否继续生成图片？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消"
    exit 1
fi

echo ""
echo "🎨 第三步：生成图片"
echo "🔗 工具：https://ai-edu.aigcfun.com/chat-tool/chat（艺术模型）"
echo ""

# 打开新标签页
open "https://ai-edu.aigcfun.com/chat-tool/chat"

echo ""
echo "📝 请按以下步骤操作："
echo "   1. 选择【艺术模型】"
echo "   2. 上传效果图 + 输入中文 AI 提示词"
echo "   3. 如果有多种提示词，打开多个网页并行生成"
echo "   4. 等待生成图片"
echo ""

read -p "✅ 图片生成完毕，是否继续？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消"
    exit 1
fi

echo ""
echo "💾 请将生成的图片保存到：$WORKSPACE/picture-generation/generated/$DATE/"
echo ""

read -p "✅ 图片已保存，是否继续 4K 高清化？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消"
    exit 1
fi

echo ""
echo "🖼️ 第四步：4K 高清化"
echo "🔗 工具：https://www.xingliu.art/"
echo ""

open "https://www.xingliu.art/"

echo ""
echo "📝 请按以下步骤操作："
echo "   1. 上传生成的图片"
echo "   2. 选择 4K 高清化"
echo "   3. 等待处理完成"
echo ""

read -p "✅ 高清化完成，是否下载最终图片？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消"
    exit 1
fi

echo ""
echo "💾 请将高清图片保存到：$WORKSPACE/picture-generation/final/$DATE/"
echo ""

echo "✅ 商单生图流程完成！"
echo ""
echo "📁 最终输出位置：$WORKSPACE/picture-generation/final/$DATE/"
echo "🎨 第五步：用 PS 出图（用户手动完成）"
echo ""
