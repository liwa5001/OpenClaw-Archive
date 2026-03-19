#!/usr/bin/env python3
"""
在极简地图背景上叠加精确的城市标记点
使用手动校准的参考点来推算城市位置
"""

import matplotlib.pyplot as plt
from matplotlib.patches import Circle
import matplotlib.image as mpimg
import numpy as np

# 读取原始地图图片
bg_image_path = '/Users/liwang/.openclaw/workspace/world-map-ppt-template-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

print(f"📐 原始图片尺寸：{img_width} x {img_height}")

# 手动校准的参考点 (根据世界地图视觉特征估算)
# 格式：城市名 -> (像素 x, 像素 y)
# 基于标准世界地图的视觉参考
REFERENCE_POINTS = {
    # 北美洲参考
    "Novi_ref": (285, 340),    # 美国密歇根 (五大湖区域)
    "Queretaro_ref": (215, 435), # 墨西哥中部
    
    # 欧洲参考
    "Garching_ref": (555, 305),  # 德国慕尼黑附近
    "Lodz_ref": (590, 295),      # 波兰
    
    # 亚洲参考
    "Suzhou_ref": (820, 375),    # 中国上海附近
    "Nagoya_ref": (895, 365),    # 日本本州岛
    "Bangalore_ref": (715, 465), # 印度南部
}

# 7 个城市的精确坐标 (纬度，经度)
CITIES_LON_LAT = {
    "Suzhou": (120.5853, 31.2990),      # 中国苏州
    "Bangalore": (77.5946, 12.9716),    # 印度班加罗尔
    "Queretaro": (-100.3899, 20.5888),  # 墨西哥克雷塔罗
    "Garching": (11.6519, 48.2487),     # 德国加兴
    "Novi": (-83.4755, 42.4806),        # 美国诺维 (密歇根)
    "Lodz": (19.4560, 51.7592),         # 波兰罗兹
    "Nagoya": (136.9066, 35.1815),      # 日本名古屋
}

# 创建图形
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)

# 显示背景地图
ax.imshow(img)

# 使用参考点直接定位
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 8  # 像素半径

# 绘制城市标记
for city, (x, y) in REFERENCE_POINTS.items():
    city_name = city.replace("_ref", "")
    
    print(f"📍 {city_name}: 像素 ({x}, {y})")
    
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
    ax.annotate(city_name, xy=(x, y), xytext=(x + 15, y - 10),
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
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-final-v3.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0)

print(f"\n✅ 地图生成完成！")
print(f"📂 文件位置：{output_path}")
