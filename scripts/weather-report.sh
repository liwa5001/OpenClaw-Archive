#!/bin/bash
# 上海天气预报 - 每天早上 7:00 发送
# 发送渠道：iMessage (liwa5001@hotmail.com)
# 数据源：Open-Meteo (免费，无需 API key)

set -e

cd /Users/liwang/.openclaw/workspace

# 创建日志目录
mkdir -p logs

echo "🌤️ 天气任务已触发 - $(date '+%Y-%m-%d %H:%M:%S')" >> logs/weather-report.log

# 获取日期信息
TODAY=$(date +%Y-%m-%d)
WEEKDAY=$(date +%A)

# 上海坐标
LAT=31.2304
LON=121.4737

# 获取天气数据（当前 + 未来 3 天）
WEATHER_RESULT=$(curl -s --max-time 15 "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max&timezone=Asia%2FShanghai&forecast_days=4" 2>/dev/null | python3 -c "
import json, sys
from datetime import datetime, timedelta

try:
    data = json.load(sys.stdin)
    current = data.get('current', {})
    daily = data.get('daily', {})
    
    # 当前天气
    temp = current.get('temperature_2m', 'N/A')
    humidity = current.get('relative_humidity_2m', 'N/A')
    wind = current.get('wind_speed_10m', 'N/A')
    code = current.get('weather_code', 3)
    
    codes = {0:'☀️ 晴朗', 1:'☀️ 主要晴朗', 2:'⛅ 部分多云', 3:'⛅ 多云', 45:'🌫️ 雾', 51:'🌧️ 毛毛雨', 61:'🌧️ 小雨', 63:'🌧️ 中雨', 65:'🌧️ 大雨', 71:'❄️ 小雪', 73:'❄️ 中雪', 75:'❄️ 大雪', 80:'🌦️ 阵雨', 81:'🌦️ 中雨', 82:'🌦️ 大雨', 95:'⛈️ 雷雨', 96:'⛈️ 雷阵雪', 99:'⛈️ 大雷雨'}
    desc = codes.get(code, '🌤️ 多云')
    
    current_str = f'{desc} {temp}°C | 湿度{humidity}% | 风速{wind}km/h'
    
    # 未来 3 天预报（跳过今天）
    forecast_dates = daily.get('time', [])
    forecast_codes = daily.get('weather_code', [])
    forecast_max = daily.get('temperature_2m_max', [])
    forecast_min = daily.get('temperature_2m_min', [])
    forecast_wind = daily.get('wind_speed_10m_max', [])
    
    forecast_list = []
    for i in range(1, min(4, len(forecast_dates))):  # 从明天开始，最多 3 天
        day_name = ['周一','周二','周三','周四','周五','周六','周日'][datetime.strptime(forecast_dates[i], '%Y-%m-%d').weekday()]
        fc = forecast_codes[i] if i < len(forecast_codes) else 3
        max_t = forecast_max[i] if i < len(forecast_max) else 'N/A'
        min_t = forecast_min[i] if i < len(forecast_min) else 'N/A'
        
        fc_desc = codes.get(fc, '🌤️')
        forecast_list.append(f'{day_name}: {fc_desc} {min_t}~{max_t}°C')
    
    forecast_str = ' | '.join(forecast_list)
    
    print(f'CURRENT:{current_str}')
    print(f'FORECAST:{forecast_str}')
except Exception as e:
    print(f'CURRENT:⚠️ 数据解析失败')
    print(f'FORECAST:')
" 2>/dev/null)

# 解析结果
CURRENT=$(echo "$WEATHER_RESULT" | grep "^CURRENT:" | cut -d: -f2-)
FORECAST=$(echo "$WEATHER_RESULT" | grep "^FORECAST:" | cut -d: -f2-)

if [ -z "$CURRENT" ]; then
  CURRENT="⚠️ 天气数据暂时无法获取"
fi

if [ -z "$FORECAST" ]; then
  FORECAST="  数据加载中..."
fi

# 构建天气消息
MESSAGE="🌤️ 上海天气预报 - $TODAY ($WEEKDAY)

📍 地点：上海

🌡️ 当前天气
$CURRENT

📅 未来 3 天预报
$FORECAST
💡 温馨提示
- 根据天气情况合理安排着装
- 雨天记得带伞
- 大风天气注意高空坠物

---
🏰 城堡天气助手 | 自动发送"

# 通过飞书发送
/opt/homebrew/bin/openclaw message send --channel feishu --target "ou_7781abd1e83eae23ccf01fe627f0747f" --message "$MESSAGE"

echo "✅ 天气预报已发送（飞书） - $(date)" >> logs/weather-report.log
