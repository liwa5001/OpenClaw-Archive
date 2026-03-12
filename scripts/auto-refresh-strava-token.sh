#!/bin/bash
# Strava Token 自动刷新脚本
# 检查 token 是否即将过期，如果过期则自动刷新

set -e

cd /Users/liwang/.openclaw/workspace

TOKEN_FILE="config/strava-tokens.json"

# 读取配置
if [ ! -f "$TOKEN_FILE" ]; then
  echo "❌ Token 配置文件不存在：$TOKEN_FILE"
  exit 1
fi

# 使用 Python 解析 JSON（更可靠）
if command -v python3 &> /dev/null; then
  CLIENT_ID=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['client_id'])")
  CLIENT_SECRET=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['client_secret'])")
  ACCESS_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['access_token'])")
  REFRESH_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['refresh_token'])")
  EXPIRES_AT=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['expires_at'])")
else
  # 降级使用 grep/sed
  CLIENT_ID=$(grep '"client_id"' "$TOKEN_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
  CLIENT_SECRET=$(grep '"client_secret"' "$TOKEN_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
  ACCESS_TOKEN=$(grep '"access_token"' "$TOKEN_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
  REFRESH_TOKEN=$(grep '"refresh_token"' "$TOKEN_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
  EXPIRES_AT=$(grep '"expires_at"' "$TOKEN_FILE" | sed 's/.*: *\([0-9]*\).*/\1/')
fi

# 获取当前时间戳
CURRENT_TIME=$(date +%s)

# 提前 5 分钟刷新（300 秒）
SAFE_BUFFER=300

echo "🔐 Strava Token 状态检查"
echo "========================"
echo "当前时间：$(date)"
echo "过期时间：$(date -d "@$EXPIRES_AT" 2>/dev/null || date -r "$EXPIRES_AT" 2>/dev/null || echo "无法解析")"
echo "剩余时间：$((EXPIRES_AT - CURRENT_TIME)) 秒"
echo ""

# 检查是否需要刷新
if [ $((EXPIRES_AT - CURRENT_TIME)) -lt $SAFE_BUFFER ]; then
  echo "⚠️  Token 即将过期或已过期，正在刷新..."

  # 使用 refresh token 刷新
  response=$(curl -s -X POST https://www.strava.com/oauth/token \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$REFRESH_TOKEN")

  # 检查是否刷新成功
  if echo "$response" | grep -q "Authorization Error"; then
    echo "❌ Refresh Token 已失效！"
    echo "错误信息：$response"
    echo ""
    echo "🔧 请重新授权："
    echo "   cd /Users/liwang/.openclaw/workspace && ./scripts/refresh-strava-token.sh"
    exit 1
  fi

  # 使用 Python 解析并更新配置文件
  if command -v python3 &> /dev/null; then
    python3 << EOF
import json
import sys

response = '''$response'''
try:
    data = json.loads(response)
    with open('$TOKEN_FILE', 'r') as f:
        config = json.load(f)

    config['access_token'] = data['access_token']
    config['refresh_token'] = data['refresh_token']
    config['expires_at'] = data['expires_at']
    config['last_updated'] = "$(date -Iseconds)"

    with open('$TOKEN_FILE', 'w') as f:
        json.dump(config, f, indent=2)

    print("JSON_UPDATE_SUCCESS")
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF

    if [ $? -eq 0 ]; then
      # 重新读取更新后的值
      NEW_ACCESS_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['access_token'])")
      NEW_REFRESH_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['refresh_token'])")
      NEW_EXPIRES_AT=$(python3 -c "import json; print(json.load(open('$TOKEN_FILE'))['expires_at'])")

      echo "✅ Token 刷新成功！"
      echo "   新 Access Token: ${NEW_ACCESS_TOKEN:0:20}..."
      echo "   新 Refresh Token: ${NEW_REFRESH_TOKEN:0:20}..."
      echo "   过期时间：$(date -d "@$NEW_EXPIRES_AT" 2>/dev/null || date -r "$NEW_EXPIRES_AT" 2>/dev/null)"
      echo ""

      # 输出新 token 供调用脚本使用
      echo "EXPORT_TOKENS=1"
      echo "STRAVA_TOKEN=\"$NEW_ACCESS_TOKEN\""
      echo "STRAVA_REFRESH_TOKEN=\"$NEW_REFRESH_TOKEN\""
      echo "STRAVA_EXPIRES_AT=\"$NEW_EXPIRES_AT\""
    else
      echo "❌ 更新配置文件失败"
      exit 1
    fi
  else
    echo "❌ 需要 Python3 来解析 JSON"
    exit 1
  fi

else
  echo "✅ Token 有效，无需刷新"
  echo "   Access Token: ${ACCESS_TOKEN:0:20}..."
  echo ""

  # 输出当前 token 供调用脚本使用
  echo "EXPORT_TOKENS=1"
  echo "STRAVA_TOKEN=\"$ACCESS_TOKEN\""
  echo "STRAVA_REFRESH_TOKEN=\"$REFRESH_TOKEN\""
  echo "STRAVA_EXPIRES_AT=\"$EXPIRES_AT\""
fi
