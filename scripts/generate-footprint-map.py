#!/usr/bin/env python3
"""
生成精确的公司 footprint 世界地图
在极简地图背景上精准标注 7 个城市位置
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import Circle
import numpy as np

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

# 创建图形 (16:9 比例，适合 PPT)
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)

# 设置背景为纯白色
ax.set_facecolor('#FFFFFF')
fig.patch.set_facecolor('#FFFFFF')

# 简化的世界地图轮廓 (极简风格)
# 使用非常浅的灰色绘制大陆轮廓
continents = {
    # 北美洲 (简化)
    'North America': [
        (-168, 65), (-166, 50), (-150, 45), (-130, 40), (-120, 32),
        (-115, 25), (-105, 20), (-95, 18), (-85, 18), (-80, 25),
        (-75, 35), (-70, 40), (-65, 45), (-60, 50), (-65, 60),
        (-80, 65), (-100, 70), (-130, 70), (-160, 68), (-168, 65)
    ],
    # 南美洲 (简化)
    'South America': [
        (-80, 10), (-75, 5), (-65, 5), (-50, 0), (-45, -5),
        (-40, -10), (-40, -20), (-45, -30), (-55, -40), (-65, -50),
        (-75, -50), (-80, -40), (-80, -20), (-80, -5), (-80, 10)
    ],
    # 欧洲 (简化)
    'Europe': [
        (-10, 36), (-5, 36), (0, 40), (5, 43), (10, 45), (15, 45),
        (20, 42), (25, 40), (30, 42), (30, 50), (25, 55), (20, 60),
        (15, 65), (10, 70), (5, 70), (0, 65), (-5, 60), (-10, 50), (-10, 36)
    ],
    # 非洲 (简化)
    'Africa': [
        (-15, 35), (-5, 35), (10, 35), (30, 30), (35, 20), (40, 10),
        (40, 0), (35, -10), (30, -20), (25, -30), (20, -35),
        (15, -35), (10, -30), (5, -20), (0, -10), (-5, 0),
        (-10, 10), (-15, 20), (-17, 30), (-15, 35)
    ],
    # 亚洲 (简化)
    'Asia': [
        (30, 42), (40, 40), (50, 35), (60, 30), (70, 25), (80, 20),
        (90, 20), (100, 15), (110, 15), (120, 20), (130, 30),
        (140, 35), (145, 40), (140, 45), (130, 50), (120, 55),
        (110, 60), (100, 65), (80, 70), (60, 70), (40, 65), (30, 55), (30, 42)
    ],
    # 澳大利亚 (简化)
    'Australia': [
        (115, -20), (120, -15), (130, -12), (140, -12), (150, -15),
        (155, -20), (155, -30), (150, -35), (145, -38), (135, -38),
        (125, -35), (115, -30), (113, -25), (115, -20)
    ],
}

# 绘制大陆轮廓 (非常浅的灰色，无边框线)
for name, coords in continents.items():
    x, y = zip(*coords)
    ax.fill(x, y, color='#F0F0F0', edgecolor='#E0E0E0', linewidth=0.5, alpha=0.6)

# 添加城市标记点
city_colors = {
    "Suzhou": "#2E86DE",
    "Bangalore": "#2E86DE", 
    "Queretaro": "#2E86DE",
    "Garching": "#2E86DE",
    "Novi": "#2E86DE",
    "Lodz": "#2E86DE",
    "Nagoya": "#2E86DE",
}

# 绘制城市标记 (蓝色圆点)
for city, (lat, lon) in CITIES.items():
    # 添加阴影效果 (轻微偏移的灰色圆)
    shadow = Circle((lon - 0.3, lat - 0.3), 0.8, color='#CCCCCC', alpha=0.5, zorder=1)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = Circle((lon, lat), 0.8, color=city_colors[city], alpha=0.9, zorder=2)
    ax.add_patch(marker)
    
    # 添加城市名称标签 (小字体，灰色)
    ax.annotate(city, xy=(lon, lat), xytext=(lon + 1.5, lat + 0.5),
                fontsize=8, color='#666666', weight='medium',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='white', 
                         edgecolor='none', alpha=0.8))

# 设置地图范围
ax.set_xlim(-170, 170)
ax.set_ylim(-60, 75)

# 移除坐标轴
ax.axis('off')

# 添加标题 (可选)
# ax.set_title('Company Global Footprint', fontsize=16, color='#333333', pad=20, weight='light')

# 调整布局，减少边距
plt.tight_layout(pad=0.5)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-precise.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none', 
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 地图生成完成！")
print(f"📂 文件位置：{output_path}")
print(f"\n📍 已标记城市:")
for city, (lat, lon) in CITIES.items():
    print(f"   • {city}: {lat:.2f}°N, {lon:.2f}°E")
