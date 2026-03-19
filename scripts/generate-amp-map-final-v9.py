#!/usr/bin/env python3
"""
生成 AMP HC 数据对比地图 - 最终版 v9
- 所有城市名和数据框清晰显示，不重叠
- 城市名和数据框并排排列
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

# 标签配置 - 城市名和数据框并排
# 格式：城市名 -> (引线 anchor 偏移 x, anchor 偏移 y, 标签框偏移 x, 标签框偏移 y)
LABEL_CONFIG = {
    # 亚洲
    "Suzhou": (0, -100, 0, -130),       # 正上方
    "Chengdu": (-100, 0, -140, 0),      # 正左
    "Bangalore": (0, 100, 0, 130),      # 正下方
    "Nagoya": (100, 100, 140, 130),     # 右下
    
    # 欧洲
    "Garching": (-100, 0, -140, 0),     # 正左
    "Lodz": (100, -100, 140, -130),     # 右上
    
    # 美洲
    "Novi": (-80, -80, -125, -120),     # 左上
    "Queretaro": (-100, 100, -140, 130), # 左下
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
    anchor_off_x, anchor_off_y, label_off_x, label_off_y = LABEL_CONFIG.get(city_name, (60, 0, 90, 0))
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
    
    # 城市名称标签和数据框并排 - 根据位置决定布局
    if label_x < x:  # 标签在左侧
        # 数据框 | 城市名 (数据在左，城市名在右靠近线)
        ax.annotate(f"2025: {total_2025}  →  2026: {total_2026}", 
                    xy=(label_x, label_y), xytext=(-8, 0),
                    textcoords='offset points',
                    fontsize=8, color='#222222',
                    horizontalalignment='right',
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                             edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                    zorder=40)
        
        ax.annotate(city_name, xy=(label_x, label_y), xytext=(8, 0),
                    textcoords='offset points',
                    fontsize=10, color='#555555', weight='semibold',
                    horizontalalignment='left',
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                             edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                    zorder=41)
    else:  # 标签在右侧
        # 城市名 | 数据框 (城市名在左靠近线，数据在右)
        ax.annotate(city_name, xy=(label_x, label_y), xytext=(-8, 0),
                    textcoords='offset points',
                    fontsize=10, color='#555555', weight='semibold',
                    horizontalalignment='right',
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                             edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                    zorder=40)
        
        ax.annotate(f"2025: {total_2025}  →  2026: {total_2026}", 
                    xy=(label_x, label_y), xytext=(8, 0),
                    textcoords='offset points',
                    fontsize=8, color='#222222',
                    horizontalalignment='left',
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                             edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                    zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-final-v9.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site:")
for site, data in sorted(hc_data.items()):
    if site in SITE_COORDS and (data['Total_2026'] > 0 or data['Total_2025'] > 0):
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name}: {data['Total_2025']} → {data['Total_2026']}")
