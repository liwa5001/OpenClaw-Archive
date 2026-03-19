#!/usr/bin/env python3
"""
生成 AMP HC 数据对比地图 - 最终版 v2
- Garching + Karlsbad 合并
- 显示所有中国城市（成都、上海、苏州）+ 日本 Nagoya
- 调小字体，避免遮挡
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data-v3.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

# Site 到城市坐标的映射
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),
    "Shanghai": ("Shanghai", 31.2304, 121.4737),
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

# 标签配置 - 中国城市充分错开
# 格式：城市名 -> (引线 anchor 偏移，标签框偏移)
LABEL_CONFIG = {
    # 亚洲 - 中国城市垂直充分错开
    "Suzhou": (75, 0, 100, 0),         # 正右 (太平洋)
    "Shanghai": (75, -65, 100, -90),   # 右下 (远离 Suzhou)
    "Chengdu": (-75, 0, -110, 0),      # 正左 (中亚)
    "Bangalore": (50, 55, 80, 80),     # 右下 (印度洋)
    "Nagoya": (75, 75, 100, 100),      # 右下 (太平洋，最下方)
    
    # 欧洲
    "Garching": (0, 85, 0, 115),       # 正下方
    
    # 美洲
    "Novi": (-60, -60, -90, -85),      # 左上 (大西洋)
    "Queretaro": (60, 55, 90, 80),     # 右下 (墨西哥湾)
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
    
    # 根据 2026 年 HC 总数调整标记大小
    if total_2026 >= 100:
        marker_radius = 20
    elif total_2026 >= 50:
        marker_radius = 16
    elif total_2026 >= 10:
        marker_radius = 13
    else:
        marker_radius = 10
    
    # 获取标签配置
    anchor_off_x, anchor_off_y, label_off_x, label_off_y = LABEL_CONFIG.get(city_name, (50, 0, 75, 0))
    anchor_x, anchor_y = x + anchor_off_x, y + anchor_off_y
    label_x, label_y = x + label_off_x, y + label_off_y
    
    # 外圈光晕
    glow = patches.Circle((x, y), marker_radius + 12, 
                          color=MARKER_COLOR, alpha=0.25, zorder=10)
    ax.add_patch(glow)
    
    # 阴影
    shadow = patches.Circle((x - 2, y + 2), marker_radius, 
                            color='#888888', alpha=0.5, zorder=20)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = patches.Circle((x, y), marker_radius, 
                            color=MARKER_COLOR, alpha=1.0, zorder=30)
    ax.add_patch(marker)
    
    # 白色内圈
    inner = patches.Circle((x, y), marker_radius - 5, 
                           color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 绘制引线
    line_x = [x, anchor_x, label_x]
    line_y = [y, anchor_y, label_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35)
    
    # 引线连接点
    anchor_dot = patches.Circle((anchor_x, anchor_y), 3, 
                                color=MARKER_COLOR, alpha=0.8, zorder=36)
    ax.add_patch(anchor_dot)
    
    # 城市名称标签 - 调小字体
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(0, 22),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40)
    
    # HC 数据对比标签 - 调小字体
    data_text = f"2025: {total_2025}  →  2026: {total_2026}"
    
    ax.annotate(data_text, xy=(label_x, label_y), xytext=(0, -18),
                textcoords='offset points',
                fontsize=8, color='#222222',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-final-v2.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site (2025 Jan vs 2026 Feb):")
for site, data in sorted(hc_data.items()):
    if site in SITE_COORDS and (data['Total_2026'] > 0 or data['Total_2025'] > 0):
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name}: {data['Total_2025']} → {data['Total_2026']}")
