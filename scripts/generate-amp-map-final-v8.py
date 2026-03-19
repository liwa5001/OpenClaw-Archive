#!/usr/bin/env python3
"""
生成 AMP HC 数据对比地图 - 最终版 v8
- 修复 Lodz 和 Nagoya 城市名显示
- 修复 Garching 位置
- 所有标签清晰显示
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data-v4.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

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
}

# 读取背景地图
bg_image_path = '/Users/liwang/.openclaw/workspace/Temp/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(20, 9), dpi=150)
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

# 标签配置 - 每个城市独立调整
# 格式：城市名 -> (引线 anchor 偏移 x, anchor 偏移 y, 标签框偏移 x, 标签框偏移 y, 数据框偏移 x, 数据框偏移 y, 城市名对齐 ha, 城市名对齐 va)
LABEL_CONFIG = {
    # 亚洲
    "Suzhou": (0, -100, 0, -140, 0, -8, 'center', 'bottom'),
    "Chengdu": (-100, 0, -150, 0, 8, 0, 'right', 'center'),
    "Bangalore": (0, 100, 0, 140, 0, 8, 'center', 'top'),
    "Nagoya": (100, 100, 150, 140, -8, 0, 'right', 'center'),
    
    # 欧洲
    "Garching": (-100, 0, -150, 0, 8, 0, 'right', 'center'),
    "Lodz": (100, -100, 150, -140, 0, 8, 'center', 'bottom'),
    
    # 美洲
    "Novi": (-80, -80, -125, -120, 0, 8, 'center', 'bottom'),
    "Queretaro": (-100, 100, -150, 140, 8, 0, 'right', 'center'),
}

# 绘制有数据的 Site
for site, data in hc_data.items():
    if site not in SITE_COORDS:
        continue
    
    total_2025 = data['Total_2025']
    total_2026 = data['Total_2026']
    
    if total_2026 == 0 and total_2025 == 0:
        continue
    
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    # 获取标签配置
    config = LABEL_CONFIG.get(city_name, (60, 0, 90, 0, 0, 10, 'left', 'center'))
    anchor_off_x, anchor_off_y, label_off_x, label_off_y, data_off_x, data_off_y, ha, va = config
    
    anchor_x, anchor_y = x + anchor_off_x, y + anchor_off_y
    label_x, label_y = x + label_off_x, y + label_off_y
    
    # 外圈光晕
    glow = patches.Circle((x, y), MARKER_RADIUS + 12, 
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
    inner = patches.Circle((x, y), MARKER_RADIUS - 5, 
                           color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 绘制引线
    line_x = [x, anchor_x]
    line_y = [y, anchor_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35)
    
    # 城市名称标签
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(0, 0),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                horizontalalignment=ha, verticalalignment=va,
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40)
    
    # HC 数据对比标签
    data_text = f"2025: {total_2025}  →  2026: {total_2026}"
    
    ax.annotate(data_text, xy=(label_x, label_y), xytext=(data_off_x, data_off_y),
                textcoords='offset points',
                fontsize=8, color='#222222',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-final-v8.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site:")
for site, data in sorted(hc_data.items()):
    if site in SITE_COORDS and (data['Total_2026'] > 0 or data['Total_2025'] > 0):
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name}: {data['Total_2025']} → {data['Total_2026']}")
