#!/usr/bin/env python3
"""
在标准 Mercator 投影地图上添加 AMP HC 数据 v2
优化标签布局，避免重叠，添加更多中国城市
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

# Site 到城市坐标的映射 (显示名称，纬度，经度)
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),       # 中国苏州
    "Bangalore": ("Bangalore", 12.9716, 77.5946),  # 印度班加罗尔
    "Nagoya": ("Nagoya", 35.1815, 136.9066),       # 日本名古屋
    "Garching": ("Garching", 48.2487, 11.6519),    # 德国加兴
    "Farmington Hills": ("Novi", 42.4806, -83.4755), # 美国诺维
    "Juarez": ("Juarez", 31.6904, -106.4245),      # 墨西哥华雷斯
    "Shanghai": ("Shanghai", 31.2304, 121.4737),   # 中国上海
    "Chengdu": ("Chengdu", 30.5728, 104.0668),     # 中国成都
    "Karlsbad": ("Karlsbad", 49.2167, 12.8333),    # 德国卡尔斯巴德
    "Szekesfehervar": ("Szekesfehervar", 47.1925, 18.4100), # 匈牙利
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

# 标签偏移配置 - 精心调整避免重叠
# 格式：城市名 -> (城市标签偏移 x, 城市标签偏移 y, 数据标签偏移 x, 数据标签偏移 y)
LABEL_OFFSETS = {
    "Suzhou": (-40, 35, -40, 5),    # 左下 (远离 Nagoya)
    "Bangalore": (35, 30, 35, 10),  # 右下
    "Nagoya": (40, -40, 40, -20),   # 右上 (太平洋区域)
    "Garching": (-45, -40, -45, -20), # 左上
    "Novi": (40, -40, 40, -20),     # 右上
    "Juarez": (40, 30, 40, 10),     # 右下
    "Shanghai": (-40, -40, -40, -20), # 左上 (远离 Suzhou)
    "Chengdu": (-40, 35, -40, 5),   # 左下
    "Karlsbad": (35, 30, 35, 10),   # 右下
    "Szekesfehervar": (35, -40, 35, -20), # 右上
}

# 绘制有数据的 Site (跳过 HC=0 的)
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
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-2026-v2.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.02)

print(f"✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site:")
for site, data in hc_data.items():
    if site in SITE_COORDS and data['Total_2026'] > 0:
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name} ({site}): {data['Total_2026']} 人 (Int:{data['Internal_2026']}, Ext:{data['External_2026']})")
