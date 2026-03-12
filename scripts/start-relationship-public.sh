#!/bin/bash
# 关系堡公网访问自动启动脚本

WORKSPACE="/Users/liwang/.openclaw/workspace"
LOG_DIR="$WORKSPACE/logs"

echo "🚀 启动关系堡公网访问服务..."

# 检查并启动本地服务器
if ! curl -s "http://localhost:8899" > /dev/null 2>&1; then
    echo "📡 启动关系堡本地服务器..."
    cd "$WORKSPACE/relationship-form"
    nohup node server.js > "$LOG_DIR/relationship-server.log" 2>&1 &
    sleep 2
    echo "✅ 本地服务器已启动 (端口 8899)"
else
    echo "✅ 本地服务器已运行"
fi

# 检查并启动内网穿透
if ! curl -s "https://$(cat $LOG_DIR/lt-relationship.log 2>/dev/null | grep -o '[a-z-]*\.loca\.lt' | head -1)" > /dev/null 2>&1; then
    echo "🌐 启动内网穿透..."
    pkill -f "lt --port 8899" 2>/dev/null
    sleep 1
    cd "$WORKSPACE"
    nohup lt --port 8899 > "$LOG_DIR/lt-relationship.log" 2>&1 &
    sleep 3
    
    PUBLIC_URL=$(cat "$LOG_DIR/lt-relationship.log" | grep -o "https://[a-z-]*\.loca\.lt" | head -1)
    
    if [ -n "$PUBLIC_URL" ]; then
        echo "✅ 内网穿透已启动"
        echo "🌐 公网链接：$PUBLIC_URL"
        
        # 发送到飞书
        echo "📬 发送公网链接到飞书..."
        /opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "💕 **关系堡问卷 - 新链接**

🌐 **公网访问链接：**
$PUBLIC_URL

✅ 可在任何网络环境下访问
📱 手机/电脑都能用
⚠️ 首次访问提示'不安全'是正常的，点击继续即可

🏰 城堡关系堡 | 随时随地，记录关系！"
    else
        echo "❌ 内网穿透启动失败"
    fi
else
    PUBLIC_URL=$(cat "$LOG_DIR/lt-relationship.log" 2>/dev/null | grep -o "https://[a-z-]*\.loca\.lt" | head -1)
    echo "✅ 内网穿透已运行"
    echo "🌐 公网链接：$PUBLIC_URL"
fi

echo "✅ 关系堡公网访问服务已就绪！"
