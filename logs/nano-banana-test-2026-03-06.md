# Nano Banana Pro 测试失败记录

**测试时间：** 2026-03-06 13:36  
**测试内容：** 生成穿粉色和服的 Hello Kitty 图片  
**尝试次数：** 5/5 次

---

## ❌ 失败原因

**错误信息：** `Error: No API key provided.`

**原因分析：**
1. 环境变量 `GEMINI_API_KEY` 未设置
2. `~/.openclaw/openclaw.json` 中未配置 Gemini API key
3. 当前仅配置了 OpenAI 和 Qwen 的 API key

---

## 🔧 解决方案

### 方案 1：设置环境变量（推荐）
```bash
export GEMINI_API_KEY="your-gemini-api-key"
```

### 方案 2：通过 --api-key 参数传递
```bash
uv run ~/.openclaw/workspace/skills/nano-banana-pro/scripts/generate_image.py \
  --prompt "Hello Kitty wearing a pink kimono" \
  --filename "test.png" \
  --resolution 1K \
  --api-key "your-gemini-api-key"
```

### 方案 3：获取 Gemini API Key
1. 访问 https://aistudio.google.com/apikey
2. 登录 Google 账号
3. 创建新的 API key
4. 复制到剪贴板

---

## 📋 测试详情

| 尝试 | 时间 | 结果 | 错误 |
|------|------|------|------|
| 1 | 13:36:00 | ❌ | No API key |
| 2 | 13:36:02 | ❌ | No API key |
| 3 | 13:36:04 | ❌ | No API key |
| 4 | 13:36:06 | ❌ | No API key |
| 5 | 13:36:08 | ❌ | No API key |

**脚本路径：** `/Users/liwang/.openclaw/workspace/skills/nano-banana-pro/scripts/generate_image.py`  
**uv 状态：** ✅ 已安装 (`/opt/homebrew/bin/uv`)  
**GEMINI_API_KEY：** ❌ 未配置

---

**记录者：** 城堡 🏰
