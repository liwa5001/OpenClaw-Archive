#!/usr/bin/env python3
"""
在极简地图背景上叠加精确的城市标记点
保持原有地图风格，只添加蓝色标记点和标签
"""

import matplotlib.pyplot as plt
from matplotlib.patches import Circle
import matplotlib.image as mpimg
import numpy as np

# 7 个城市的精确坐标 (纬度，经度)
CITIES = {
    "Suzhou": (31.2990, 120.5853),      # 中国苏州
    "Bangalore": (12.9716, 77.5946),    # 印度班加罗尔
    "Queretaro": (20.5888, -100.3899),  # 墨西哥克雷塔罗
    "Garching": (48.2487, 11.6519),     # 德国加兴
    "Novi": (42.4806, -83.4755),        # 美国诺维 (密歇根)
    "Lodz": (51.7592, 19.4560),         # 波兰罗兹
    "Nagoya": (35.1815, 136.9066),      # 日本名古屋
}

# 读取原始地图图片
bg_image_path = '/Users/liwang/.openclaw/workspace/world-map-ppt-template-v2.png'
img = mpimg.imread(bg_image_path)

# 创建图形 (保持原图比例)
height, width = img.shape[:2]
aspect_ratio = width / height

fig, ax = plt.subplots(figsize=(16, 9), dpi=150)

# 显示背景地图
ax.imshow(img, extent=[-180, 180, -90, 90])

# 城市标记颜色 - 商务蓝色
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 0.9  # 标记点半径

# 绘制城市标记 (蓝色圆点 + 阴影)
for city, (lat, lon) in CITIES.items():
    # 添加阴影效果 (轻微偏移的灰色圆，营造凹凸感)
    shadow = Circle((lon - 0.4, lat - 0.4), MARKER_RADIUS, 
                    color='#999999', alpha=0.4, zorder=1)
    ax.add_patch(shadow)
    
    # 蓝色标记点 (主标记)
    marker = Circle((lon, lat), MARKER_RADIUS, 
                    color=MARKER_COLOR, alpha=0.95, zorder=2)
    ax.add_patch(marker)
    
    # 添加外圈光晕效果
    glow = Circle((lon, lat), MARKER_RADIUS + 0.3, 
                  color=MARKER_COLOR, alpha=0.2, zorder=0)
    ax.add_patch(glow)
    
    # 添加城市名称标签 (小字体，深灰色，带白色背景框)
    offset_x = 2.0
    offset_y = 0.8
    ax.annotate(city, xy=(lon, lat), xytext=(lon + offset_x, lat + offset_y),
                fontsize=9, color='#333333', weight='medium',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                         edgecolor='none', alpha=0.9))

# 设置地图范围 (与背景图匹配)
ax.set_xlim(-180, 180)
ax.set_ylim(-90, 90)

# 移除坐标轴
ax.axis('off')

# 调整布局
plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-final.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0)

print(f"✅ 地图生成完成！")
print(f"📂 文件位置：{output_path}")
print(f"\n📍 已标记 7 个城市:")
for city, (lat, lon) in CITIES.items():
    print(f"   • {city}: {lat:.2f}°N, {lon:.2f}°E")
