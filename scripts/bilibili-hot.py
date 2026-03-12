#!/usr/bin/env python3
"""
B 站热门视频抓取 - 使用 Jina AI 提取标题和链接
用法：python3 bilibili-hot.py
"""

import requests
import re
from datetime import datetime

def fetch_bilibili_hot():
    """抓取 B 站热门视频"""
    
    try:
        # 使用 Jina AI 读取 B 站热门页面
        response = requests.get(
            "https://r.jina.ai/https://www.bilibili.com/v/popular/ranking/all",
            timeout=15
        )
        response.raise_for_status()
        
        content = response.text
        
        # 提取视频链接（从 Markdown 图片链接中提取）
        video_urls = re.findall(r'\(https://www\.bilibili\.com/video/BV[a-zA-Z0-9]+\)', content)
        video_urls = [url.strip('()') for url in video_urls]
        
        if not video_urls:
            print("❌ 未找到视频链接")
            return []
        
        print(f"📺 B 站热门视频 Top{len(video_urls)} - {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
        
        # 获取每个视频的标题
        for i, url in enumerate(video_urls[:10], 1):
            bvid = url.split('/video/')[-1]
            
            try:
                video_resp = requests.get(f"https://r.jina.ai/{url}", timeout=10)
                video_content = video_resp.text
                
                # 提取标题（清理多余内容）
                title_match = re.search(r'Title:\s*(.+?)(?:_哔哩哔哩|$)', video_content)
                if title_match:
                    title = title_match.group(1).strip()
                    # 清理标题中的多余字符
                    title = re.sub(r'\.mp4$', '', title)
                    title = re.sub(r'^https?://\S+\s*', '', title)
                else:
                    title = bvid
                
                # 如果标题是 URL 或空，用 BV 号代替
                if title.startswith('http') or not title or len(title) < 3:
                    title = f"视频 {bvid}"
                
                print(f"{i}. {title}")
                print(f"   🔗 {url}\n")
                
            except Exception as e:
                print(f"{i}. 视频 {bvid}")
                print(f"   🔗 {url}\n")
        
        return video_urls[:10]
        
    except requests.exceptions.RequestException as e:
        print(f"❌ 网络错误：{e}")
        return []
    except Exception as e:
        print(f"❌ 错误：{e}")
        return []

if __name__ == "__main__":
    fetch_bilibili_hot()
