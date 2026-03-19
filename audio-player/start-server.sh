#!/bin/bash
# 启动音频播放器服务器
cd /Users/liwang/.openclaw/workspace/audio-player

# 启动 HTTP 服务器（端口 8895）
python3 -m http.server 8895 > ../../logs/audio-player.log 2>&1 &
echo $! > ../../logs/audio-player.pid

# 等待服务器启动
sleep 2

# 启动 Cloudflare Tunnel
cloudflared tunnel --url http://localhost:8895 > ../../logs/cloudflared-audio.log 2>&1 &
echo $! > ../../logs/cloudflared-audio.pid

# 等待 Tunnel 启动
sleep 5

# 获取公网链接
PUBLIC_URL=$(grep trycloudflare ../../logs/cloudflared-audio.log | grep -oE 'https://[^ ]+trycloudflare\.com' | head -1)
echo "$PUBLIC_URL" > ../../logs/audio-player-url.txt

echo "音频播放器已启动："
echo "本地：http://localhost:8895"
echo "公网：$PUBLIC_URL"
