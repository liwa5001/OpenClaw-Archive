#!/bin/bash

# 明天提醒选声音
# 添加到 cron 或 HEARTBEAT.md

MESSAGE="🎧 **有声读本声音优化提醒**

昨晚搭建的有声读本系统运行正常，但你说声音不太自然。

**当前声音：** macOS 系统 TTS（Mei-Jia）
**问题：** 机械感较强，不够自然

**可选方案：**

1. **Edge TTS（推荐）** ⭐
   - 声音：zh-CN-XiaoxiaoNeural（女生）
   - 特点：免费、自然度高、支持情感
   - 安装：\`pip install edge-tts\`

2. **ElevenLabs（付费）**
   - 声音：超自然 AI 语音
   - 特点：最自然、支持克隆
   - 成本：$5/月起

3. **Azure TTS（付费）**
   - 声音：多种中文女声
   - 特点：自然、稳定
   - 成本：按量计费

**建议：** 先用 Edge TTS（免费），效果不好再考虑付费方案。

今晚下班前我继续用当前声音生成，明天你决定要不要换～"

cd /Users/liwang/.openclaw/workspace
openclaw message send --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 已发送声音优化提醒"
