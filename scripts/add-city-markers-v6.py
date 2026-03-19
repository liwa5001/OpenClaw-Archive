#!/usr/bin/env python3
"""
在极简地图背景上叠加精确的城市标记点
v6: 修复标签重叠，调整城市位置
"""

import matplotlib.pyplot as plt
from matplotlib.patches import Circle
import matplotlib.image as mpimg

# 读取原始地图图片
bg_image_path = '/Users/liwang/.openclaw/workspace/world-map-ppt-template-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)
ax.imshow(img)

# 根据地图实际大陆轮廓校准的位置 (v6 改进版)
CITIES_PIXELS = {
    # 北美洲
    "Novi": (275, 370),       # 密歇根州 - 五大湖区域，底特律西北
    "Queretaro": (210, 455),  # 墨西哥 - 墨西哥城西北
    
    # 欧洲 - 分开标签避免重叠
    "Garching": (555, 345),   # 德国 - 慕尼黑附近
    "Lodz": (595, 325),       # 波兰 - 华沙西侧
    
    # 亚洲
    "Suzhou": (800, 405),     # 中国 - 上海/苏州
    "Nagoya": (875, 395),     # 日本 - 本州岛中部
    "Bangalore": (700, 480),  # 印度 - 南部
}

# 标签偏移量 (避免重叠)
LABEL_OFFSETS = {
    "Novi": (18, -12),
    "Queretaro": (18, -12),
    "Garching": (18, -20),    # 向上偏移，给 Lodz 留空间
    "Lodz": (18, 15),         # 向下偏移
    "Suzhou": (18, -12),
    "Nagoya": (18, -12),
    "Bangalore": (18, -12),
}

# 城市标记样式
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 9

# 绘制城市标记
for city, (x, y) in CITIES_PIXELS.items():
    # 阴影效果
    shadow = Circle((x - 2, y + 2), MARKER_RADIUS, 
                    color='#999999', alpha=0.4, zorder=1)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = Circle((x, y), MARKER_RADIUS, 
                    color=MARKER_COLOR, alpha=0.95, zorder=2)
    ax.add_patch(marker)
    
    # 外圈光晕
    glow = Circle((x, y), MARKER_RADIUS + 5, 
                  color=MARKER_COLOR, alpha=0.15, zorder=0)
    ax.add_patch(glow)
    
    # 获取标签偏移
    offset_x, offset_y = LABEL_OFFSETS.get(city, (18, -12))
    
    # 城市名称标签
    ax.annotate(city, xy=(x, y), xytext=(x + offset_x, y + offset_y),
                fontsize=10, color='#333333', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor='none', alpha=0.95))

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-final-v6.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0)

print(f"✅ 地图生成完成：{output_path}")
