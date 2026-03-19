#!/usr/bin/env python3
"""
在标准 Mercator 投影地图上添加 AMP HC 数据
显示每个 site 2026 年 2 月的 Internal 和 External 数据
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

print("📊 读取的 Site 数据:")
for site, data in hc_data.items():
    print(f"  {site}: 2026 Total={data['Total_2026']} (Int={data['Internal_2026']}, Ext={data['External_2026']})")

# Site 到城市坐标的映射 (Site 名，纬度，经度)
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),       # 中国苏州
    "Bangalore": ("Bangalore", 12.9716, 77.5946),  # 印度班加罗尔
    "Nagoya": ("Nagoya", 35.1815, 136.9066),       # 日本名古屋
    "Garching": ("Garching", 48.2487, 11.6519),    # 德国加兴
    "Farmington Hills": ("Novi", 42.4806, -83.4755), # 美国诺维 (靠近 Farmington Hills)
    "Juarez": ("Juarez", 31.6904, -106.4245),      # 墨西哥华雷斯
    # 以下 Site 没有直接对应城市，需要估算或跳过
    # "Chengdu": 成都
    # "Karlsbad": 德国卡尔斯巴德
    # "Shanghai": 上海
    # "Szekesfehervar": 匈牙利塞克什白堡
}

# 读取背景地图
bg_image_path = '/Users/liwang/.openclaw/workspace/Temp/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

print(f"\n📐 地图尺寸：{img_width} x {img_height}")

# 创建图形 (16:9 比例)
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

# 标签偏移配置
LABEL_OFFSETS = {
    "Suzhou": (35, 30),         # 右下
    "Bangalore": (35, 25),      # 右下
    "Nagoya": (35, -35),        # 右上
    "Garching": (-40, -35),     # 左上
    "Novi": (40, -35),          # 右上
    "Juarez": (40, 30),         # 右下
}

# 绘制有数据的 Site
for site, data in hc_data.items():
    if site not in SITE_COORDS:
        print(f"⚠️  跳过未知位置：{site}")
        continue
    
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    total_2026 = data['Total_2026']
    int_2026 = data['Internal_2026']
    ext_2026 = data['External_2026']
    
    # 根据 HC 总数调整标记大小 (越大越重要)
    size_factor = 1 + (total_2026 / 200)  # 基准 200 人
    marker_radius = MARKER_RADIUS * size_factor
    
    print(f"📍 {site} ({city_name}): 像素 ({x:.1f}, {y:.1f}), HC={total_2026}")
    
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
    
    # 获取标签偏移
    offset_x, offset_y = LABEL_OFFSETS.get(city_name, (35, -35))
    
    # 城市名称标签
    ax.annotate(city_name, xy=(x, y), xytext=(x + offset_x, y + offset_y - 25),
                textcoords='data',
                fontsize=11, color='#555555', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.9),
                zorder=40)
    
    # HC 数据标签 (2026 年 2 月数据)
    data_text = f"2026: {total_2026}\n(Int:{int_2026}, Ext:{ext_2026})"
    ax.annotate(data_text, xy=(x, y), xytext=(x + offset_x, y + offset_y + 5),
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
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-2026.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.02)

print(f"\n✅ 地图生成完成：{output_path}")
