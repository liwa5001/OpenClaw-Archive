#!/usr/bin/env python3
"""
在标准 Mercator 投影地图上添加 AMP HC 数据 v3
优化亚洲和欧洲区域的标签布局，避免重叠
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

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
MARKER_RADIUS = 14

# 标签偏移配置 - 每个城市独立调整
# 格式：城市名 -> (城市标签偏移 x, 城市标签偏移 y, 数据标签偏移 x, 数据标签偏移 y)
LABEL_OFFSETS = {
    # 亚洲 - 精心布局避免重叠
    "Suzhou": (0, 45, 0, 20),       # 正下方 (中国东部)
    "Shanghai": (0, 65, 0, 40),     # 更下方 (远离 Suzhou)
    "Chengdu": (-50, 0, -70, 0),    # 正左方 (中国西部)
    "Bangalore": (40, 35, 40, 15),  # 右下 (印度)
    "Nagoya": (45, -45, 45, -25),   # 右上 (日本)
    
    # 欧洲 - 分散布局
    "Garching": (-55, 0, -75, 0),   # 正左方 (德国)
    "Karlsbad": (-55, 25, -75, 25), # 左方 (德国东部)
    "Szekesfehervar": (45, -50, 45, -30), # 右上 (匈牙利)
    
    # 美洲
    "Novi": (45, -45, 45, -25),     # 右上 (美国)
    "Juarez": (45, 35, 45, 15),     # 右下 (墨西哥)
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
    
    # 根据 HC 总数调整标记大小
    size_factor = 1 + (total_2026 / 200)
    marker_radius = MARKER_RADIUS * size_factor
    
    # 获取标签偏移
    city_off_x, city_off_y, data_off_x, data_off_y = LABEL_OFFSETS.get(city_name, (35, -35, 35, -15))
    
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
    inner = patches.Circle((x, y), marker_radius - 5, 
                           color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 城市名称标签
    ax.annotate(city_name, xy=(x, y), xytext=(x + city_off_x, y + city_off_y),
                textcoords='data',
                fontsize=11, color='#555555', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.9),
                zorder=40)
    
    # HC 数据标签
    data_text = f"2026: {total_2026}\n(Int:{int_2026}, Ext:{ext_2026})"
    ax.annotate(data_text, xy=(x, y), xytext=(x + data_off_x, y + data_off_y),
                textcoords='data',
                fontsize=9, color='#222222',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor=MARKER_COLOR, linewidth=1, alpha=0.95),
                zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-2026-v3.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.02)

print(f"✅ 地图生成完成：{output_path}")
