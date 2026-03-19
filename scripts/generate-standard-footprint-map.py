#!/usr/bin/env python3
"""
生成标准 Mercator 投影的世界地图
极简商务风格 + 精确城市坐标标记
"""

import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import numpy as np

# 7 个城市的精确坐标 (纬度，经度)
CITIES = {
    "Suzhou": (31.2990, 120.5853),      # 中国苏州
    "Bangalore": (12.9716, 77.5946),    # 印度班加罗尔
    "Queretaro": (20.5888, -100.3899),  # 墨西哥克雷塔罗
    "Garching": (48.2487, 11.6519),     # 德国加兴 (慕尼黑附近)
    "Novi": (42.4806, -83.4755),        # 美国诺维 (密歇根)
    "Lodz": (51.7592, 19.4560),         # 波兰罗兹
    "Nagoya": (35.1815, 136.9066),      # 日本名古屋
}

# 创建图形 (16:9 比例，适合 PPT)
fig = plt.figure(figsize=(16, 9), dpi=150)

# 使用 Mercator 投影
ax = plt.axes(projection=ccrs.Mercator())

# 设置地图范围 (覆盖主要大陆)
ax.set_extent([-170, 170, -60, 75], crs=ccrs.PlateCarree())

# 添加极简风格的大陆轮廓
# 非常浅的灰色填充，几乎看不见的边框
ax.add_feature(cfeature.LAND, facecolor='#F5F5F5', edgecolor='#E0E0E0', linewidth=0.3, alpha=0.8)
ax.add_feature(cfeature.OCEAN, facecolor='#FFFFFF', alpha=1.0)

# 添加非常淡的海岸线
ax.add_feature(cfeature.COASTLINE, linewidth=0.5, edgecolor='#D0D0D0', alpha=0.6)

# 不添加国界线、州界线等 (保持极简)
# 不添加河流、湖泊细节 (保持简洁)

# 城市标记样式
MARKER_COLOR = "#2E86DE"  # 商务蓝色
MARKER_SIZE = 100  # 标记点大小 (s 参数)

# 绘制城市标记
for city, (lat, lon) in CITIES.items():
    # 在地图上绘制点
    ax.plot(lon, lat, 'o', color=MARKER_COLOR, markersize=10, 
            transform=ccrs.PlateCarree(), alpha=0.9, zorder=5)
    
    # 添加外圈光晕效果
    ax.plot(lon, lat, 'o', color=MARKER_COLOR, markersize=14, 
            transform=ccrs.PlateCarree(), alpha=0.2, zorder=4)
    
    # 添加城市名称标签
    # 根据城市位置智能调整标签偏移，避免重叠
    if city == "Garching":
        offset = (-15, -12)  # 左下
    elif city == "Lodz":
        offset = (12, 8)     # 右上
    elif city == "Novi":
        offset = (12, -12)   # 右下
    elif city == "Bangalore":
        offset = (12, -12)   # 右下
    else:
        offset = (12, -12)   # 默认右下
    
    ax.annotate(city, xy=(lon, lat), xytext=offset,
                textcoords='offset points',
                fontsize=10, color='#333333', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor='none', alpha=0.95),
                transform=ccrs.PlateCarree(), zorder=6)

# 移除经纬度网格线
ax.gridlines(color='#E0E0E0', linewidth=0.3, alpha=0.3, linestyle='--')

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-standard-footprint.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.05)

print(f"✅ 标准投影地图生成完成！")
print(f"📂 文件位置：{output_path}")
print(f"\n📍 已标记城市 (精确经纬度):")
for city, (lat, lon) in CITIES.items():
    print(f"   • {city}: {lat:.4f}°N, {lon:.4f}°E")
