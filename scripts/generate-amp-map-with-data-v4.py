#!/usr/bin/env python3
"""
在标准 Mercator 投影地图上添加 AMP HC 数据 v4
使用引线标签，将拥挤区域的标签拉到远处空白区域
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json
from matplotlib.path import Path

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

# Site 到城市坐标的映射
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),
    "Bangalore": ("Bangalore", 12.9716, 77.5946),
    "Nagoya": ("Nagoya", 35.1815, 136.9066),
    "Garching": ("Garching", 48.2487, 11.6519),
    "Farmington Hills": ("Novi", 42.4806, -83.4755),
    "Juarez": ("Juarez", 31.6904, -106.4245),
    "Shanghai": ("Shanghai", 31.2304, 121.4737),
    "Chengdu": ("Chengdu", 30.5728, 104.0668),
    "Karlsbad": ("Karlsbad", 49.2167, 12.8333),
    "Szekesfehervar": ("Szekesfehervar", 47.1925, 18.4100),
}

# 读取背景地图
bg_image_path = '/Users/liwang/.openclaw/workspace/Temp/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(18, 9), dpi=150)
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

# 标签配置 - 使用引线布局
# 格式：城市名 -> (标签框 anchor 点相对标记的偏移，标签框位置偏移)
LABEL_CONFIG = {
    # 亚洲 - 拉到海洋区域
    "Suzhou": ((80, 0), (100, 0)),     # 向右拉到太平洋
    "Shanghai": ((80, -25), (100, -25)), # 向右上，避免和 Suzhou 重叠
    "Chengdu": ((-80, 0), (-120, 0)),  # 向左拉到中亚
    "Bangalore": ((60, 40), (80, 60)), # 右下 (印度洋)
    "Nagoya": ((70, -50), (90, -70)),  # 右上 (太平洋)
    
    # 欧洲 - 分散
    "Garching": ((-70, 0), (-100, 0)), # 左 (大西洋)
    "Karlsbad": ((-70, 30), (-100, 30)), # 左上
    "Szekesfehervar": ((70, -60), (90, -80)), # 右上
    
    # 美洲
    "Novi": ((60, -50), (80, -70)),    # 右上
    "Juarez": ((60, 40), (80, 60)),    # 右下
}

# 绘制有数据的 Site
for site, data in hc_data.items():
    if site not in SITE_COORDS:
        continue
    
    total_2026 = data['Total_2026']
    if total_2026 == 0:
        continue
    
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    int_2026 = data['Internal_2026']
    ext_2026 = data['External_2026']
    
    # 根据 HC 总数调整标记大小 (HC 少的标记小)
    if total_2026 >= 100:
        marker_radius = 18
    elif total_2026 >= 50:
        marker_radius = 15
    elif total_2026 >= 10:
        marker_radius = 12
    else:
        marker_radius = 9
    
    # 获取标签配置
    anchor_offset, label_offset = LABEL_CONFIG.get(city_name, ((50, 0), (70, 0)))
    anchor_x, anchor_y = x + anchor_offset[0], y + anchor_offset[1]
    label_x, label_y = x + label_offset[0], y + label_offset[1]
    
    # 外圈光晕
    glow = patches.Circle((x, y), marker_radius + 10, 
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
    inner = patches.Circle((x, y), marker_radius - 4, 
                           color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 绘制引线 (从标记到标签框)
    line_x = [x, anchor_x, label_x]
    line_y = [y, anchor_y, label_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35)
    
    # 引线连接点 (小圆点)
    anchor_dot = patches.Circle((anchor_x, anchor_y), 3, 
                                color=MARKER_COLOR, alpha=0.8, zorder=36)
    ax.add_patch(anchor_dot)
    
    # 城市名称标签
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(0, 20),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40)
    
    # HC 数据标签
    data_text = f"2026: {total_2026}\n(Int:{int_2026}, Ext:{ext_2026})"
    ax.annotate(data_text, xy=(label_x, label_y), xytext=(0, -15),
                textcoords='offset points',
                fontsize=9, color='#222222',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-2026-v4.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.02)

print(f"✅ 地图生成完成：{output_path}")
