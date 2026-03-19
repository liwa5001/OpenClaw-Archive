---
name: picture_generation
description: 商单生图流程 - 通过客户需求和效果图生成 AI 提示词，然后用艺术模型生成图片并 4K 高清化
---

# picture_generation - 商单生图 Skill

## 功能说明

通过输入客户商单需求和一张效果图，生成客户需要的高清图片。

## 工作流程

### 第一步：接收需求
- 用户提供：客户需求文字 + 效果图（1 张）
- 保存路径：`/workspace/picture-generation/input/`

### 第二步：生成 AI 提示词
**工具：** https://ai-edu.aigcfun.com/chat-tool/chat（高阶模型）

**操作：**
1. 打开浏览器访问上述网址
2. 选择"高阶模型"
3. 输入提示词（拆解图片）：
   ```
   详细拆解这张图片需要从主体内容，场景设定，风格参考，色调，色彩，构图，视角，细节补充这些角度，再用文字描述图片并汇总成一个能够用于 AI 作图工具文生图的提示词和英文提示词。
   要求成品图满足以下要求：[客户需求]
   ```
4. 上传效果图
5. 等待生成中文 AI 提示词（可能有 1-3 种）

**🛑 暂停点：** 生成提示词后，**必须等用户确认**才能继续

**确认后：** 保存提示词到 `/workspace/picture-generation/prompts/YYYY-MM-DD-prompts.md`

### 第三步：生成图片
**工具：** https://ai-edu.aigcfun.com/chat-tool/chat（艺术模型）

**操作：**
1. 打开浏览器访问上述网址
2. 选择"艺术模型"
3. 上传效果图 + 输入中文 AI 提示词
4. 如果有多种提示词，打开多个网页并行生成
5. 等待生成图片

**🛑 暂停点：** 生成图片后，**必须等用户确认**才能继续

**确认后：** 下载图片到 `/workspace/picture-generation/generated/YYYY-MM-DD-generated/`

### 第四步：4K 高清化
**工具：** https://www.xingliu.art/

**操作：**
1. 打开浏览器访问上述网址
2. 上传生成的图片
3. 选择 4K 高清化
4. 等待处理完成

**🛑 暂停点：** 高清化完成后，**必须等用户确认**才能继续

**确认后：** 下载高清图片到 `/workspace/picture-generation/final/YYYY-MM-DD-final/`

### 第五步：PS 出图
**用户手动完成**（AI 不参与）

---

## 文件结构

```
/workspace/picture-generation/
├── input/           # 客户原始需求 + 效果图
├── prompts/         # 生成的 AI 提示词
├── generated/       # 生成的图片
└── final/           # 4K 高清化后的最终图片
```

---

## 使用方法

```bash
# 启动商单生图流程
./scripts/picture-generation.sh
```

或直接在对话中调用此 skill。

---

## 注意事项

1. **每个关键步骤都必须暂停等用户确认**
2. 提示词可能有多个版本，全部保存供用户选择
3. 图片生成建议并行处理（多个提示词 = 多个浏览器标签页）
4. 所有文件按日期归档，方便追溯

---

**维护者：** 城堡 🏰  
**创建日期：** 2026-03-19
