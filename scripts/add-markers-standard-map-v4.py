#!/usr/bin/env python3
"""
在标准 Mercator 投影地图上添加精确的城市标记 v4
调整标签位置，避免遮挡标记点和大陆
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math

# 7 个城市的精确坐标
CITIES = {
    "Suzhou": (31.2990, 120.5853),
    "Bangalore": (12.9716, 77.5946),
    "Queretaro": (20.5888, -100.3899),
    "Garching": (48.2487, 11.6519),
    "Novi": (42.4806, -83.4755),
    "Lodz": (51.7592, 19.4560),
    "Nagoya": (35.1815, 136.9066),
}

# 读取背景地图
bg_image_path = '/Users/liwang/.openclaw/workspace/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)
ax.imshow(img)

# Mercator 投影转换
def mercator_to_pixel(lon, lat, map_width, map_height):
    x = (lon + 180) / 360 * map_width
    lat_rad = math.radians(lat)
    merc_y = math.log(math.tan(math.pi/4 + lat_rad/2))
    max_merc_y = math.log(math.tan(math.pi/4 + math.radians(85)/2))
    y_normalized = merc_y / max_merc_y
    y = (1 - y_normalized) / 2 * map_height
    return x, y

# 城市标记样式
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 12

# 标签偏移 - 每个城市不同方向，避免重叠和遮挡
LABEL_OFFSETS = {
    "Garching": (-35, -30),   # 左上 (远离 Lodz)
    "Lodz": (30, 25),         # 右下 (远离 Garching)
    "Novi": (35, -30),        # 右上
    "Bangalore": (35, 25),    # 右下 (海洋区域)
    "Suzhou": (35, 25),       # 右下 (海洋区域)
    "Nagoya": (35, 30),       # 右下 (太平洋区域)
    "Queretaro": (35, 25),    # 右下 (墨西哥湾区域)
}

# 绘制城市标记
for city, (lat, lon) in CITIES.items():
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    # 外圈光晕
    glow = patches.Circle((x, y), MARKER_RADIUS + 8, 
                          color=MARKER_COLOR, alpha=0.25, zorder=10)
    ax.add_patch(glow)
    
    # 阴影
    shadow = patches.Circle((x - 2, y + 2), MARKER_RADIUS, 
                            color='#888888', alpha=0.5, zorder=20)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = patches.Circle((x, y), MARKER_RADIUS, 
                            color=MARKER_COLOR, alpha=1.0, zorder=30)
    ax.add_patch(marker)
    
    # 白色内圈
    inner = patches.Circle((x, y), MARKER_RADIUS - 4, 
                           color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 标签偏移
    offset_x, offset_y = LABEL_OFFSETS.get(city, (35, -25))
    
    # 城市名称标签 (增加背景 padding)
    ax.annotate(city, xy=(x, y), xytext=(x + offset_x, y + offset_y),
                textcoords='data',
                fontsize=12, color='#222222', weight='bold',
                bbox=dict(boxstyle='round,pad=0.7', facecolor='white', 
                         edgecolor='#DDDDDD', linewidth=1, alpha=0.95),
                zorder=40)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-standard-final-v4.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.02)

print(f"✅ 地图生成完成：{output_path}")
