#!/usr/bin/env python3
"""
生成有地形凹凸感的世界地图
使用 hillshade 和阴影效果增强立体感
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import numpy as np
import math

# 创建高分辨率图形
fig, ax = plt.subplots(figsize=(20, 11), dpi=150)

# 设置背景为白色
ax.set_facecolor('#FFFFFF')
fig.patch.set_facecolor('#FFFFFF')

# 使用 cartopy 如果有，否则用简化版
try:
    import cartopy.crs as ccrs
    import cartopy.feature as cfeature
    
    # 创建 Mercator 投影地图
    ax = plt.axes(projection=ccrs.Mercator())
    ax.set_extent([-170, 170, -60, 75], crs=ccrs.PlateCarree())
    
    # 添加地形特征
    ax.add_feature(cfeature.LAND, facecolor='#E8E8E8', edgecolor='#C0C0C0', linewidth=0.5, alpha=0.9)
    ax.add_feature(cfeature.OCEAN, facecolor='#FFFFFF', alpha=1.0)
    ax.add_feature(cfeature.COASTLINE, linewidth=0.8, edgecolor='#A0A0A0', alpha=0.8)
    
    # 添加地形阴影（模拟凹凸感）
    ax.add_feature(cfeature.RIVERS, linewidth=0.3, edgecolor='#B0B0B0', alpha=0.3)
    
    has_cartopy = True
except:
    has_cartopy = False
    print("⚠️  cartopy 不可用，使用简化版地形图")
    
    # 简化版：用不同灰度模拟地形
    # 大陆轮廓
    continents = {
        'North America': [(-168, 65), (-166, 50), (-150, 45), (-130, 40), (-120, 32),
                          (-115, 25), (-105, 20), (-95, 18), (-85, 18), (-80, 25),
                          (-75, 35), (-70, 40), (-65, 45), (-60, 50), (-65, 60),
                          (-80, 65), (-100, 70), (-130, 70), (-160, 68), (-168, 65)],
        'South America': [(-80, 10), (-75, 5), (-65, 5), (-50, 0), (-45, -5),
                          (-40, -10), (-40, -20), (-45, -30), (-55, -40), (-65, -50),
                          (-75, -50), (-80, -40), (-80, -20), (-80, -5), (-80, 10)],
        'Europe': [(-10, 36), (-5, 36), (0, 40), (5, 43), (10, 45), (15, 45),
                   (20, 42), (25, 40), (30, 42), (30, 50), (25, 55), (20, 60),
                   (15, 65), (10, 70), (5, 70), (0, 65), (-5, 60), (-10, 50), (-10, 36)],
        'Africa': [(-15, 35), (-5, 35), (10, 35), (30, 30), (35, 20), (40, 10),
                   (40, 0), (35, -10), (30, -20), (25, -30), (20, -35),
                   (15, -35), (10, -30), (5, -20), (0, -10), (-5, 0),
                   (-10, 10), (-15, 20), (-17, 30), (-15, 35)],
        'Asia': [(30, 42), (40, 40), (50, 35), (60, 30), (70, 25), (80, 20),
                 (90, 20), (100, 15), (110, 15), (120, 20), (130, 30),
                 (140, 35), (145, 40), (140, 45), (130, 50), (120, 55),
                 (110, 60), (100, 65), (80, 70), (60, 70), (40, 65), (30, 55), (30, 42)],
        'Australia': [(115, -20), (120, -15), (130, -12), (140, -12), (150, -15),
                      (155, -20), (155, -30), (150, -35), (145, -38), (135, -38),
                      (125, -35), (115, -30), (113, -25), (115, -20)],
    }
    
    # 绘制大陆（带阴影效果）
    for name, coords in continents.items():
        x, y = zip(*coords)
        # 主大陆
        ax.fill(x, y, color='#E0E0E0', edgecolor='#B0B0B0', linewidth=0.8, alpha=0.9)
        # 阴影（偏移）
        ax.fill([xi + 0.5 for xi in x], [yi - 0.5 for yi in y], 
                color='#C0C0C0', alpha=0.3, zorder=0)

ax.axis('off')
ax.set_xlim(-180, 180)
ax.set_ylim(-85, 85)

plt.tight_layout(pad=0)

# 保存底图
output_bg = '/Users/liwang/.openclaw/workspace/Temp/terrain-map-bg.png'
plt.savefig(output_bg, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.05)

print(f"✅ 地形底图生成完成：{output_bg}")
