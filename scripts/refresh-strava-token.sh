#!/bin/bash
# Strava Token 刷新脚本

set -e

cd /Users/liwang/.openclaw/workspace

TOKEN_FILE="config/strava-tokens.json"

# 读取配置
if [ ! -f "$TOKEN_FILE" ]; then
  echo "❌ Token 配置文件不存在：$TOKEN_FILE"
  exit 1
fi

# 使用 Python 解析 JSON
if command -v python3 &> /dev/null; then
  CLIENT_ID=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['client_id'])")
  CLIENT_SECRET=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['client_secret'])")
  REFRESH_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['refresh_token'])")
else
  echo "❌ 需要 Python3 来解析 JSON"
  exit 1
fi

echo "🔐 Strava Token 刷新工具"
echo "========================"
echo ""
echo "当前配置："
echo "  Client ID: $CLIENT_ID"
echo "  Refresh Token: ${REFRESH_TOKEN:0:20}..."
echo ""

echo "请选择刷新方式："
echo "1. 使用 Refresh Token 自动刷新"
echo "2. 手动输入新的 Access Token"
echo "3. 重新授权获取新 Token"
echo ""
read -p "选择 (1-3): " choice

case $choice in
  1)
    if [ -z "$REFRESH_TOKEN" ]; then
      echo "❌ 配置文件中没有 Refresh Token，请选择方式 3 重新授权"
      exit 1
    fi

    echo "🔄 使用 Refresh Token 刷新..."
    response=$(curl -s -X POST https://www.strava.com/oauth/token \
      -d "client_id=$CLIENT_ID" \
      -d "client_secret=$CLIENT_SECRET" \
      -d "grant_type=refresh_token" \
      -d "refresh_token=$REFRESH_TOKEN")

    if echo "$response" | grep -q "Authorization Error"; then
      echo "❌ Refresh Token 已失效，请选择方式 3 重新授权"
      exit 1
    fi

    # 使用 Python 解析响应并更新配置
    python3 << EOF
import json
import sys

try:
    data = json.loads('''$response''')
    with open('$TOKEN_FILE', 'r') as f:
        config = json.load(f)

    config['access_token'] = data['access_token']
    config['refresh_token'] = data['refresh_token']
    config['expires_at'] = data['expires_at']
    config['last_updated'] = "$(date -Iseconds)"

    with open('$TOKEN_FILE', 'w') as f:
        json.dump(config, f, indent=2)

    print("配置已更新！")
    print(f"   Access Token: {data['access_token'][:20]}...")
    print(f"   Refresh Token: {data['refresh_token'][:20]}...")
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
    ;;

  2)
    read -p "请输入新的 Access Token: " new_token
    read -p "请输入新的 Refresh Token: " new_refresh
    read -p "请输入过期时间戳 (expires_at): " new_expires

    python3 << EOF
import json
try:
    with open('$TOKEN_FILE', 'r') as f:
        config = json.load(f)
    config['access_token'] = "$new_token"
    config['refresh_token'] = "$new_refresh"
    config['expires_at'] = int($new_expires) if "$new_expires" else 0
    config['last_updated'] = "$(date -Iseconds)"
    with open('$TOKEN_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    print("✅ Token 已更新！")
except Exception as e:
    print(f"Error: {e}")
EOF
    ;;

  3)
    echo ""
    echo "📋 请按以下步骤操作："
    echo "1. 访问：https://www.strava.com/settings/api"
    echo "2. 查看你的应用：Client ID = $CLIENT_ID"
    echo "3. 点击 'Your Access Token' 查看或重新生成"
    echo "   ⚠️  确保权限包含：read,activity:read_all"
    echo "4. 记录 Access Token 和 Refresh Token"
    echo ""
    echo "🔧 或者使用授权流程（推荐）："
    echo ""
    echo "授权 URL（复制到浏览器）："
    echo "https://www.strava.com/oauth/authorize?client_id=${CLIENT_ID}&redirect_uri=http://localhost/exchange_token&response_type=code&scope=read,activity:read_all"
    echo ""
    echo "注意：授权后会跳转到 localhost 失败页面，从 URL 中提取 code 参数"
    echo "例如：http://localhost/exchange_token?state=&code=xxx&scope=read,activity:read_all"
    echo ""
    read -p "获取到 Authorization Code 后输入： " auth_code

    if [ -n "$auth_code" ]; then
      response=$(curl -s -X POST https://www.strava.com/oauth/token \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "code=$auth_code" \
        -d "grant_type=authorization_code")

      python3 << EOF
import json
try:
    data = json.loads('''$response''')
    with open('$TOKEN_FILE', 'r') as f:
        config = json.load(f)
    config['access_token'] = data['access_token']
    config['refresh_token'] = data['refresh_token']
    config['expires_at'] = data['expires_at']
    config['last_updated'] = "$(date -Iseconds)"
    with open('$TOKEN_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    print("✅ Token 已更新！")
    print(f"   Access Token: {data['access_token'][:20]}...")
    print(f"   Refresh Token: {data['refresh_token'][:20]}...")
except Exception as e:
    print(f"Error: {e}")
    print(f"响应: $response")
EOF
    fi
    ;;

  *)
    echo "❌ 无效选择"
    exit 1
    ;;
esac

echo ""
echo "🎉 完成！运行以下命令测试："
echo "   cd /Users/liwang/.openclaw/workspace && ./scripts/analyze-workout.sh"
