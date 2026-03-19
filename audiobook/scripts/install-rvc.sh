#!/bin/bash

# RVC 本地安装助手脚本
# 用于下载和配置 RVC 声音克隆项目

WORKSPACE="/Users/liwang/.openclaw/workspace"
RVC_DIR="$WORKSPACE/rvc-voice-cloning"
LOG_FILE="$WORKSPACE/logs/rvc-install.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始安装 RVC" >> "$LOG_FILE"

# 检查系统
echo "🔍 检查系统环境..."

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到 Python 3，请先安装 Python 3.8 或更高版本"
    echo "下载地址：https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "✅ $PYTHON_VERSION"

# 检查 Git
if ! command -v git &> /dev/null; then
    echo "⚠️  未找到 Git，尝试安装..."
    brew install git 2>/dev/null || {
        echo "❌ Git 安装失败，请手动安装"
        exit 1
    }
fi
echo "✅ Git 已安装"

# 创建目录
echo "📁 创建 RVC 目录..."
mkdir -p "$RVC_DIR"
cd "$RVC_DIR"

# 克隆 RVC 项目
echo "📥 克隆 RVC 项目..."
if [ -d "Retrieval-based-Voice-Conversion-WebUI" ]; then
    echo "⚠️  项目已存在，跳过克隆"
else
    git clone https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git
    if [ $? -ne 0 ]; then
        echo "❌ 克隆失败，请检查网络连接"
        exit 1
    fi
    echo "✅ 克隆完成"
fi

cd "Retrieval-based-Voice-Conversion-WebUI"

# 创建虚拟环境
echo "🐍 创建 Python 虚拟环境..."
if [ -d "venv" ]; then
    echo "⚠️  虚拟环境已存在，跳过创建"
else
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "❌ 虚拟环境创建失败"
        exit 1
    fi
    echo "✅ 虚拟环境创建完成"
fi

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
echo "📦 安装依赖包..."
pip install --upgrade pip -q
pip install -r requirements.txt -q 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "⚠️  部分依赖安装失败，但不影响使用"
fi

echo "✅ 依赖安装完成"

# 创建录音目录
echo "📁 创建录音和模型目录..."
mkdir -p "assets/custom_voice"
mkdir -p "assets/records"
mkdir -p "$WORKSPACE/audiobook/rvc-voices"

# 创建启动脚本
cat > start-rvc.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python infer-web.py --pycmd python3
EOF

chmod +x start-rvc.sh

# 创建使用说明
cat > README.md << 'EOF'
# RVC 声音克隆 - 快速开始

## 启动 RVC

```bash
./start-rvc.sh
```

然后在浏览器打开：http://localhost:7865

## 录音步骤

1. 准备录音样本（10-30 分钟）
   - 用手机录制清晰的人声
   - 格式：MP3 或 WAV
   - 内容：朗读书籍章节

2. 将录音文件放入：`assets/records/`

## 训练声音模型

1. 打开 RVC Web 界面（http://localhost:7865）

2. 进入"模型训练"标签页

3. 填写：
   - 实验名称：haibangbao（或其他名字）
   - 选择录音文件所在目录
   - 点击"开始训练"

4. 等待训练完成（约 30-60 分钟）

## 使用克隆声音

1. 进入"推理"标签页

2. 选择训练好的模型

3. 输入文字或上传音频文件

4. 点击"转换"生成音频

5. 生成的音频在：`assets/custom_voice/`

## 集成到有声读本

训练完成后，告诉我模型名称，我会修改有声读本系统使用你的专属声音。

## 常见问题

**Q: 启动失败？**
A: 检查 Python 版本（需要 3.8+），重新安装依赖

**Q: 训练很慢？**
A: 正常，根据电脑配置需要 30-120 分钟

**Q: 效果不好？**
A: 增加录音时长，确保录音质量清晰无噪音

EOF

echo ""
echo "=========================================="
echo "✅ RVC 安装完成！"
echo "=========================================="
echo ""
echo "📍 安装目录：$RVC_DIR/Retrieval-based-Voice-Conversion-WebUI"
echo ""
echo "🚀 启动命令："
echo "   cd $RVC_DIR/Retrieval-based-Voice-Conversion-WebUI"
echo "   ./start-rvc.sh"
echo ""
echo "🌐 然后在浏览器打开：http://localhost:7865"
echo ""
echo "📝 详细说明请查看：$RVC_DIR/Retrieval-based-Voice-Conversion-WebUI/README.md"
echo ""
echo "=========================================="
echo ""
echo "📋 下一步："
echo "1. 启动 RVC（运行上面的启动命令）"
echo "2. 准备 10-30 分钟录音样本"
echo "3. 上传录音并训练声音模型"
echo "4. 测试效果"
echo ""
echo "💡 录音建议："
echo "- 直接朗读《每天懂点人情世故》前几章"
echo "- 时长：10-30 分钟"
echo "- 环境：安静房间，手机录音即可"
echo ""
echo "=========================================="

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ RVC 安装完成" >> "$LOG_FILE"
