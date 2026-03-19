#!/usr/bin/env python3
"""
在有凹凸感的地形图上添加 AMP HC 数据
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import pandas as pd

# 读取数据
df = pd.read_csv('/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary-final-v2.csv')
hc_data = {}
for _, row in df.iterrows():
    hc_data[row['Site']] = {
        'Total_2025': int(row['Total_2025']),
        'Total_2026': int(row['Total_2026']),
    }

# Site 坐标
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),
    "Lodz": ("Lodz", 51.7592, 19.4560),
    "Chengdu": ("Chengdu", 30.5728, 104.0668),
    "Bangalore": ("Bangalore", 12.9716, 77.5946),
    "Nagoya": ("Nagoya", 35.1815, 136.9066),
    "Garching": ("Garching", 48.2487, 11.6519),
    "Novi": ("Novi", 42.4806, -83.4755),
    "Queretaro": ("Queretaro", 20.5888, -100.3899),
}

# 读取地形底图
bg_path = '/Users/liwang/.openclaw/workspace/Temp/terrain-map-bg.png'
img = mpimg.imread(bg_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(20, 11), dpi=150)
ax.imshow(img)

# Mercator 转换
def mercator_to_pixel(lon, lat, map_width, map_height):
    x = (lon + 180) / 360 * map_width
    lat_rad = math.radians(lat)
    merc_y = math.log(math.tan(math.pi/4 + lat_rad/2))
    max_merc_y = math.log(math.tan(math.pi/4 + math.radians(85)/2))
    y_normalized = merc_y / max_merc_y
    y = (1 - y_normalized) / 2 * map_height
    return x, y

# 样式
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 16

# 标签配置
LABEL_CONFIG = {
    "Suzhou": (0, -100, 0, -130),
    "Chengdu": (-100, 0, -140, 0),
    "Bangalore": (0, 100, 0, 130),
    "Nagoya": (50, 150, 90, 200),
    "Garching": (-100, 0, -140, 0),
    "Lodz": (100, -100, 140, -130),
    "Novi": (-80, -80, -125, -120),
    "Queretaro": (-100, 100, -140, 130),
}

# 绘制
for site, data in hc_data.items():
    if site not in SITE_COORDS:
        continue
    
    total_2025 = data['Total_2025']
    total_2026 = data['Total_2026']
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    anchor_off_x, anchor_off_y, label_off_x, label_off_y = LABEL_CONFIG.get(city_name, (60, 0, 90, 0))
    anchor_x, anchor_y = x + anchor_off_x, y + anchor_off_y
    label_x, label_y = x + label_off_x, y + label_off_y
    
    # 外圈光晕（增强立体感）
    for i in range(3, 0, -1):
        glow = patches.Circle((x, y), MARKER_RADIUS + 8 + i*4, 
                              color=MARKER_COLOR, alpha=0.15/i, zorder=10+i)
        ax.add_patch(glow)
    
    # 阴影（增强凹凸感）
    shadow = patches.Circle((x - 3, y + 3), MARKER_RADIUS + 2, 
                            color='#606060', alpha=0.4, zorder=20)
    ax.add_patch(shadow)
    
    # 蓝色标记点（渐变效果）
    marker = patches.Circle((x, y), MARKER_RADIUS, 
                            color=MARKER_COLOR, alpha=1.0, zorder=30)
    ax.add_patch(marker)
    
    # 高光（增强立体感）
    highlight = patches.Circle((x - 4, y - 4), MARKER_RADIUS * 0.4, 
                               color='white', alpha=0.5, zorder=31)
    ax.add_patch(highlight)
    
    # 引线（带渐变）
    line_x = [x, anchor_x]
    line_y = [y, anchor_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=2, alpha=0.7, zorder=35)
    
    # 城市名标签
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(-8, 0),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                horizontalalignment='right',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40)
    
    # 数据标签
    ax.annotate(f"2025: {total_2025}  →  2026: {total_2026}", 
                xy=(label_x, label_y), xytext=(8, 0),
                textcoords='offset points',
                fontsize=8, color='#222222',
                horizontalalignment='left',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1.5, alpha=0.98),
                zorder=41)

ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-terrain.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 凹凸感地图生成完成：{output_path}")
