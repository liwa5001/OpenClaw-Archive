#!/usr/bin/env python3
"""
在极简地图背景上叠加精确的城市标记点
根据视觉特征手动校准每个城市位置
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

# 创建图形
fig, ax = plt.subplots(figsize=(16, 9), dpi=150)
ax.imshow(img)

# 根据视觉特征手动校准的城市位置 (像素坐标)
# 基于标准世界地图的地理特征估算
CITIES_PIXELS = {
    # 北美洲
    "Novi": (295, 365),      # 美国密歇根州 - 五大湖区域西侧
    "Queretaro": (225, 460), # 墨西哥 - 墨西哥城西北
    
    # 欧洲
    "Garching": (565, 325),  # 德国 - 慕尼黑附近 (阿尔卑斯山北侧)
    "Lodz": (605, 310),      # 波兰 - 华沙西侧
    
    # 亚洲
    "Suzhou": (810, 395),    # 中国 - 上海/苏州区域 (长江入海口)
    "Nagoya": (885, 380),    # 日本 - 本州岛中部 (东京和大阪之间)
    "Bangalore": (710, 485), # 印度 - 德干高原南部
}

# 城市标记样式
MARKER_COLOR = "#2E86DE"
MARKER_RADIUS = 9  # 像素半径

# 绘制城市标记
for city, (x, y) in CITIES_PIXELS.items():
    print(f"📍 {city}: 像素 ({x}, {y})")
    
    # 阴影效果 (右下方向)
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
    
    # 城市名称标签 (右侧偏移)
    ax.annotate(city, xy=(x, y), xytext=(x + 18, y - 12),
                fontsize=10, color='#333333', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor='none', alpha=0.95))

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)  # 图像坐标系 y 轴向下

# 调整布局
plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-final-v4.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0)

print(f"\n✅ 地图生成完成！")
print(f"📂 文件位置：{output_path}")
print("\n💡 如果位置还需要调整，告诉我哪个城市需要往哪个方向移动")
