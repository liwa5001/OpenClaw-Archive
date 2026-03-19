#!/usr/bin/env python3
"""
在极简地图背景上叠加精确的城市标记点
使用 Mercator 投影转换经纬度到像素坐标
"""

import matplotlib.pyplot as plt
from matplotlib.patches import Circle
import matplotlib.image as mpimg
import numpy as np
import math

# 7 个城市的精确坐标 (纬度，经度)
CITIES = {
    "Suzhou": (31.2990, 120.5853),      # 中国苏州
    "Bangalore": (12.9716, 77.5946),    # 印度班加罗尔
    "Queretaro": (20.5888, -100.3899),  # 墨西哥克雷塔罗
    "Garching": (48.2487, 11.6519),     # 德国加兴
    "Novi": (42.4806, -83.4755),        # 美国诺维 (密歇根)
    "Lodz": (51.7592, 19.4560),         # 波兰罗兹
    "Nagoya": (35.1815, 136.9066),      # 日本名古屋
}

# 读取原始地图图片
bg_image_path = '/Users/liwang/.openclaw/workspace/world-map-ppt-template-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

print(f"📐 原始图片尺寸：{img_width} x {img_height}")

# 创建图形
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)

# 显示背景地图
ax.imshow(img)

# Mercator 投影转换函数
def lat_lon_to_pixel(lat, lon, width, height):
    """
    将经纬度转换为像素坐标 (Mercator 投影)
    假设地图覆盖 -180 到 180 经度，-85 到 85 纬度
    """
    # 经度 -> x 坐标 (线性映射)
    x = (lon + 180) / 360 * width
    
    # 纬度 -> y 坐标 (Mercator 投影)
    lat_rad = math.radians(lat)
    mercator_n = math.log(math.tan((math.pi / 4) + (lat_rad / 2)))
    y = (1 - mercator_n / math.pi) / 2 * height
    
    return x, y

# 城市标记颜色 - 商务蓝色
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 8  # 像素半径

# 绘制城市标记
for city, (lat, lon) in CITIES.items():
    x, y = lat_lon_to_pixel(lat, lon, img_width, img_height)
    
    print(f"📍 {city}: 经纬度 ({lat}, {lon}) -> 像素 ({x:.1f}, {y:.1f})")
    
    # 添加阴影效果
    shadow = Circle((x - 2, y + 2), MARKER_RADIUS, 
                    color='#999999', alpha=0.4, zorder=1)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = Circle((x, y), MARKER_RADIUS, 
                    color=MARKER_COLOR, alpha=0.95, zorder=2)
    ax.add_patch(marker)
    
    # 添加外圈光晕
    glow = Circle((x, y), MARKER_RADIUS + 4, 
                  color=MARKER_COLOR, alpha=0.15, zorder=0)
    ax.add_patch(glow)
    
    # 添加城市名称标签
    ax.annotate(city, xy=(x, y), xytext=(x + 15, y - 10),
                fontsize=9, color='#333333', weight='medium',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                         edgecolor='none', alpha=0.9))

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)  # 图像坐标系 y 轴向下

# 调整布局
plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-final-v2.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0)

print(f"\n✅ 地图生成完成！")
print(f"📂 文件位置：{output_path}")
