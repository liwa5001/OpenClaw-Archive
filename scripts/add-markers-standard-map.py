#!/usr/bin/env python3
"""
在标准 Mercator 投影地图上添加精确的城市标记
使用真实经纬度坐标定位
"""

import matplotlib.pyplot as plt
from matplotlib.patches import Circle
import matplotlib.image as mpimg
import math

# 7 个城市的精确坐标 (纬度，经度)
CITIES = {
    "Suzhou": (31.2990, 120.5853),      # 中国苏州
    "Bangalore": (12.9716, 77.5946),    # 印度班加罗尔
    "Queretaro": (20.5888, -100.3899),  # 墨西哥克雷塔罗
    "Garching": (48.2487, 11.6519),     # 德国加兴
    "Novi": (42.4806, -83.4755),        # 美国诺维
    "Lodz": (51.7592, 19.4560),         # 波兰罗兹
    "Nagoya": (35.1815, 136.9066),      # 日本名古屋
}

# 读取标准地图背景
bg_image_path = '/Users/liwang/.openclaw/workspace/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

print(f"📐 地图尺寸：{img_width} x {img_height}")

# 创建图形
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)
ax.imshow(img, extent=[-180, 180, -85, 85])

# Mercator 投影转换：经纬度 -> 地图坐标
def mercator_project(lon, lat, map_width, map_height):
    """
    将经纬度转换为 Mercator 投影的地图坐标
    地图范围：经度 -180~180，纬度 -85~85 (Mercator 标准范围)
    """
    # 经度 -> x (线性)
    x = (lon + 180) / 360 * map_width
    
    # 纬度 -> y (Mercator 投影公式)
    lat_rad = math.radians(lat)
    # Mercator Y 公式
    merc_y = math.log(math.tan(math.pi/4 + lat_rad/2))
    # 限制在 -85~85 度范围内
    max_merc_y = math.log(math.tan(math.pi/4 + math.radians(85)/2))
    y = (1 - merc_y / max_merc_y) / 2 * map_height
    
    return x, y

# 城市标记样式
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 10

# 标签偏移 (避免重叠)
LABEL_OFFSETS = {
    "Garching": (-20, -15),  # 左下
    "Lodz": (15, 10),        # 右上
    "Novi": (15, -15),       # 右下
    "Bangalore": (15, -15),  # 右下
    "Suzhou": (15, -15),     # 右下
    "Nagoya": (15, -15),     # 右下
    "Queretaro": (15, -15),  # 右下
}

# 绘制城市标记
for city, (lat, lon) in CITIES.items():
    x, y = mercator_project(lon, lat, img_width, img_height)
    
    print(f"📍 {city}: ({lat:.2f}°N, {lon:.2f}°E) -> ({x:.1f}, {y:.1f})")
    
    # 外圈光晕
    glow = Circle((x, y), MARKER_RADIUS + 6, 
                  color=MARKER_COLOR, alpha=0.2, zorder=1)
    ax.add_patch(glow)
    
    # 阴影
    shadow = Circle((x - 1.5, y + 1.5), MARKER_RADIUS, 
                    color='#999999', alpha=0.4, zorder=2)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = Circle((x, y), MARKER_RADIUS, 
                    color=MARKER_COLOR, alpha=0.95, zorder=3)
    ax.add_patch(marker)
    
    # 标签偏移
    offset_x, offset_y = LABEL_OFFSETS.get(city, (15, -15))
    
    # 城市名称标签
    ax.annotate(city, xy=(x, y), xytext=(x + offset_x, y + offset_y),
                textcoords='data',
                fontsize=11, color='#333333', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor='none', alpha=0.95),
                zorder=4)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(-180, 180)
ax.set_ylim(-85, 85)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-standard-final.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.02)

print(f"\n✅ 地图生成完成！")
print(f"📂 文件位置：{output_path}")
