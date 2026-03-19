#!/usr/bin/env python3
"""
生成可编辑的 SVG 格式 AMP HC 地图
可以用 Inkscape、Illustrator 或文本编辑器调整标签位置
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary-fixed.csv', 'r', encoding='utf-8') as f:
    import pandas as pd
    df = pd.read_csv(f)

# 转换为字典
hc_data = {}
for _, row in df.iterrows():
    hc_data[row['Site']] = {
        'Total_2025': int(row['Total_2025']),
        'Total_2026': int(row['Total_2026']),
    }

# Site 到城市坐标的映射
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),
    "Lodz": ("Lodz", 51.7592, 19.4560),
    "Chengdu": ("Chengdu", 30.5728, 104.0668),
    "Bangalore": ("Bangalore", 12.9716, 77.5946),
    "Nagoya": ("Nagoya", 35.1815, 136.9066),
    "Garching": ("Garching", 48.2487, 11.6519),
    "Novi": ("Novi", 42.4806, -83.4755),
    "Queretaro": ("Queretaro", 20.5888, -100.3899),
    "Unknown": ("Unknown", 0, 0),  # 不显示
}

# 读取背景地图
bg_image_path = '/Users/liwang/.openclaw/workspace/Temp/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(20, 11), dpi=150)
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
MARKER_RADIUS = 14

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
    if site not in SITE_COORDS or site == 'Unknown':
        continue
    
    total_2025 = data['Total_2025']
    total_2026 = data['Total_2026']
    
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    anchor_off_x, anchor_off_y, label_off_x, label_off_y = LABEL_CONFIG.get(city_name, (60, 0, 90, 0))
    anchor_x, anchor_y = x + anchor_off_x, y + anchor_off_y
    label_x, label_y = x + label_off_x, y + label_off_y
    
    # 外圈光晕
    glow = patches.Circle((x, y), MARKER_RADIUS + 12, color=MARKER_COLOR, alpha=0.25, zorder=10)
    ax.add_patch(glow)
    
    # 阴影
    shadow = patches.Circle((x - 2, y + 2), MARKER_RADIUS, color='#888888', alpha=0.5, zorder=20)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = patches.Circle((x, y), MARKER_RADIUS, color=MARKER_COLOR, alpha=1.0, zorder=30)
    ax.add_patch(marker)
    
    # 白色内圈
    inner = patches.Circle((x, y), MARKER_RADIUS - 5, color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 引线
    line_x = [x, anchor_x]
    line_y = [y, anchor_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35, 
            gid=f"line-{city_name}")  # 添加 SVG ID
    
    # 城市名称标签
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(-8, 0),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                horizontalalignment='right',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40, gid=f"label-{city_name}")
    
    # 数据标签
    ax.annotate(f"2025: {total_2025}  →  2026: {total_2026}", 
                xy=(label_x, label_y), xytext=(8, 0),
                textcoords='offset points',
                fontsize=8, color='#222222',
                horizontalalignment='left',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                zorder=41, gid=f"data-{city_name}")

ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存为 SVG
output_svg = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-editable.svg'
plt.savefig(output_svg, format='svg', bbox_inches='tight', pad_inches=0.1)

print(f"✅ SVG 地图生成完成：{output_svg}")
print(f"\n📝 编辑说明:")
print(f"1. 用 Inkscape 打开：inkscape {output_svg}")
print(f"2. 用 Adobe Illustrator 打开")
print(f"3. 用文本编辑器编辑（搜索 'gid=' 找到元素）")
print(f"\n🏷️ 元素 ID 格式:")
print(f"   - 引线：line-CityName")
print(f"   - 城市名：label-CityName")
print(f"   - 数据框：data-CityName")
print(f"\n💡 提示：在 Inkscape 中可以直接拖拽调整位置")
