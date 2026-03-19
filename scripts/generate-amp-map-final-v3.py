#!/usr/bin/env python3
"""
生成 AMP HC 数据对比地图 - 最终版 v3
- Suzhou + Shanghai 合并显示为 Suzhou
- 调整引线和标签框对齐
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data-v3.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

# 合并 Shanghai 到 Suzhou
if 'Shanghai' in hc_data and 'Suzhou' in hc_data:
    hc_data['Suzhou']['Total_2025'] += hc_data['Shanghai']['Total_2025']
    hc_data['Suzhou']['Total_2026'] += hc_data['Shanghai']['Total_2026']
    print("📍 已将 Shanghai 合并到 Suzhou")

# Site 到城市坐标的映射（不显示 Shanghai）
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),
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

# 标签配置 - 优化对齐
# 格式：城市名 -> (引线 anchor 偏移 x, anchor 偏移 y, 标签框偏移 x, 标签框偏移 y)
LABEL_CONFIG = {
    # 亚洲 - 中国城市充分错开
    "Suzhou": (80, 0, 120, 0),         # 正右 (太平洋)
    "Chengdu": (-80, 0, -120, 0),      # 正左 (中亚)
    "Bangalore": (55, 60, 85, 90),     # 右下 (印度洋)
    "Nagoya": (80, 80, 120, 120),      # 右下 (太平洋，最下方)
    
    # 欧洲
    "Garching": (0, 90, 0, 130),       # 正下方
    
    # 美洲
    "Novi": (-65, -65, -100, -95),     # 左上 (大西洋)
    "Queretaro": (80, 80, 140, 120),   # 右下 (墨西哥湾，垂直错开)
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
    if total_2026 >= 200:
        marker_radius = 22
    elif total_2026 >= 100:
        marker_radius = 18
    elif total_2026 >= 50:
        marker_radius = 15
    elif total_2026 >= 10:
        marker_radius = 12
    else:
        marker_radius = 9
    
    # 获取标签配置
    anchor_off_x, anchor_off_y, label_off_x, label_off_y = LABEL_CONFIG.get(city_name, (60, 0, 90, 0))
    anchor_x, anchor_y = x + anchor_off_x, y + anchor_off_y
    label_x, label_y = x + label_off_x, y + label_off_y
    
    # 计算引线角度，用于对齐标签框
    dx = label_x - anchor_x
    dy = label_y - anchor_y
    angle = math.degrees(math.atan2(dy, dx))
    
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
    
    # 绘制引线（直线）
    line_x = [x, anchor_x, label_x]
    line_y = [y, anchor_y, label_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35)
    
    # 引线连接点
    anchor_dot = patches.Circle((anchor_x, anchor_y), 3, 
                                color=MARKER_COLOR, alpha=0.8, zorder=36)
    ax.add_patch(anchor_dot)
    
    # 城市名称标签 - 根据引线方向调整对齐
    if label_x > x:  # 标签在右侧
        ha = 'left'
        label_offset_x = 10
    else:  # 标签在左侧
        ha = 'right'
        label_offset_x = -10
    
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(label_offset_x, 20),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                horizontalalignment=ha,
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40)
    
    # HC 数据对比标签 - 与城市名对齐，增加垂直间距
    data_text = f"2025: {total_2025}  →  2026: {total_2026}"
    
    ax.annotate(data_text, xy=(label_x, label_y), xytext=(label_offset_x, -20),
                textcoords='offset points',
                fontsize=8, color='#222222',
                horizontalalignment=ha,
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-final-v3.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site (2025 Jan vs 2026 Feb):")
for site, data in sorted(hc_data.items()):
    if site in SITE_COORDS and (data['Total_2026'] > 0 or data['Total_2025'] > 0):
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name}: {data['Total_2025']} → {data['Total_2026']}")
