#!/usr/bin/env python3
"""
在极简地图背景上叠加精确的城市标记点
根据实际地图大陆轮廓视觉校准
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

# 根据地图实际大陆轮廓校准的位置
# 参考地标：五大湖、墨西哥湾、地中海、印度半岛、日本群岛等
CITIES_PIXELS = {
    # 北美洲 - 参考五大湖位置
    "Novi": (270, 355),      # 密歇根州 - 五大湖区域西侧 (休伦湖/密歇根湖西南)
    "Queretaro": (205, 445), # 墨西哥 - 墨西哥湾西南，墨西哥城西北
    
    # 欧洲 - 参考地中海、波罗的海位置
    "Garching": (550, 340),  # 德国 - 阿尔卑斯山北侧，慕尼黑附近
    "Lodz": (585, 320),      # 波兰 - 波罗的海以南，华沙西侧
    
    # 亚洲 - 参考印度半岛、中国海岸线、日本群岛
    "Suzhou": (795, 400),    # 中国 - 长江入海口，上海西侧
    "Nagoya": (870, 390),    # 日本 - 本州岛中部，太平洋沿岸
    "Bangalore": (695, 475), # 印度 - 德干高原南部，孟加拉湾西侧
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
    
    # 城市名称标签
    ax.annotate(city, xy=(x, y), xytext=(x + 18, y - 12),
                fontsize=10, color='#333333', weight='semibold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                         edgecolor='none', alpha=0.95))

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-final-v5.png'
plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0)

print(f"✅ 地图生成完成：{output_path}")
print("\n📍 城市位置 (基于大陆轮廓视觉校准):")
for city, (x, y) in CITIES_PIXELS.items():
    print(f"   {city}: ({x}, {y})")
