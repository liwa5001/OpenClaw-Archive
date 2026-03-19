#!/usr/bin/env python3
"""
生成 AMP HC 数据对比地图 - 最终版 v5
- 数字框移到线条顶端，紧贴
- Garching 数据放到左边
- Nagoya 显示
- Garching 移到左边避免和 Chengdu 重叠
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.image as mpimg
import math
import json

# 读取 AMP HC 数据
with open('/Users/liwang/.openclaw/workspace/Temp/amp-hc-data-v4.json', 'r', encoding='utf-8') as f:
    hc_data = json.load(f)

# Site 到城市坐标的映射
SITE_COORDS = {
    "Suzhou": ("Suzhou", 31.2990, 120.5853),
    "Lodz": ("Lodz", 51.7592, 19.4560),
    "Chengdu": ("Chengdu", 30.5728, 104.0668),
    "Bangalore": ("Bangalore", 12.9716, 77.5946),
    "Nagoya": ("Nagoya", 35.1815, 136.9066),
    "Garching": ("Garching", 48.2487, 11.6519),
    "Novi": ("Novi", 42.4806, -83.4755),
    "Queretaro": ("Queretaro", 20.5888, -100.3899),
}

print(f"📊 读取的 HC 数据：{list(hc_data.keys())}")

# 读取背景地图
bg_image_path = '/Users/liwang/.openclaw/workspace/Temp/standard-mercator-map-bg-v2.png'
img = mpimg.imread(bg_image_path)
img_height, img_width = img.shape[:2]

# 创建图形
fig, ax = plt.subplots(figsize=(20, 9), dpi=150)
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
MARKER_RADIUS = 14  # 所有圈一样大小

# 标签配置 - 文字分布平衡
# 格式：城市名 -> (引线 anchor 偏移 x, anchor 偏移 y, 标签框偏移 x, 标签框偏移 y)
LABEL_CONFIG = {
    # 亚洲 - 苏州往上，Bangalore 往下，Nagoya 右上
    "Suzhou": (0, -90, 0, -130),       # 正上方 (黄海区域)
    "Chengdu": (-90, 0, -140, 0),      # 正左 (中亚)
    "Bangalore": (0, 95, 0, 140),      # 正下方 (印度洋)
    "Nagoya": (90, 90, 140, 135),      # 右下 (太平洋)
    
    # 欧洲 - Garching 移到左边，Lodz 右上
    "Garching": (-90, 0, -140, 0),     # 正左 (大西洋区域，远离 Chengdu)
    "Lodz": (90, -90, 140, -130),      # 右上 (波罗的海)
    
    # 美洲 - Queretaro 左边，Novi 左上
    "Novi": (-75, -75, -120, -115),    # 左上 (大西洋)
    "Queretaro": (-90, 90, -140, 135), # 左下 (太平洋)
}

# 数据框位置配置 - 紧贴城市名框
# 格式：城市名 -> (数据框相对于城市名的偏移)
DATA_OFFSETS = {
    "Suzhou": (0, -15),        # 城市名下方
    "Chengdu": (0, 0),         # 同一位置
    "Bangalore": (0, 15),      # 城市名上方
    "Nagoya": (0, 0),          # 同一位置
    "Garching": (-150, 0),     # 城市名左边
    "Lodz": (0, 0),            # 同一位置
    "Novi": (0, 0),            # 同一位置
    "Queretaro": (0, 0),       # 同一位置
}

# 绘制有数据的 Site
for site, data in hc_data.items():
    if site not in SITE_COORDS:
        continue
    
    total_2025 = data['Total_2025']
    total_2026 = data['Total_2026']
    
    if total_2026 == 0 and total_2025 == 0:
        continue
    
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    # 获取标签配置
    anchor_off_x, anchor_off_y, label_off_x, label_off_y = LABEL_CONFIG.get(city_name, (60, 0, 90, 0))
    anchor_x, anchor_y = x + anchor_off_x, y + anchor_off_y
    label_x, label_y = x + label_off_x, y + label_off_y
    
    # 外圈光晕
    glow = patches.Circle((x, y), MARKER_RADIUS + 12, 
                          color=MARKER_COLOR, alpha=0.25, zorder=10)
    ax.add_patch(glow)
    
    # 阴影
    shadow = patches.Circle((x - 2, y + 2), MARKER_RADIUS, 
                            color='#888888', alpha=0.5, zorder=20)
    ax.add_patch(shadow)
    
    # 蓝色标记点
    marker = patches.Circle((x, y), MARKER_RADIUS, 
                            color=MARKER_COLOR, alpha=1.0, zorder=30)
    ax.add_patch(marker)
    
    # 白色内圈
    inner = patches.Circle((x, y), MARKER_RADIUS - 5, 
                           color='white', alpha=0.3, zorder=31)
    ax.add_patch(inner)
    
    # 绘制引线（直线，从标记到 anchor 点）
    line_x = [x, anchor_x]
    line_y = [y, anchor_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35)
    
    # 城市名称标签 - 根据引线方向调整对齐
    if label_y < y:  # 标签在上方
        va = 'bottom'
        label_offset_y = 8
    else:  # 标签在下方
        va = 'top'
        label_offset_y = -8
    
    if label_x < x:  # 标签在左侧
        ha = 'right'
        label_offset_x = -8
    else:  # 标签在右侧
        ha = 'left'
        label_offset_x = 8
    
    ax.annotate(city_name, xy=(label_x, label_y), xytext=(label_offset_x, label_offset_y),
                textcoords='offset points',
                fontsize=10, color='#555555', weight='semibold',
                horizontalalignment=ha, verticalalignment=va,
                bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F8F8', 
                         edgecolor='#DDDDDD', linewidth=0.5, alpha=0.95),
                zorder=40)
    
    # HC 数据对比标签 - 紧贴城市名框
    data_text = f"2025: {total_2025}  →  2026: {total_2026}"
    
    # 获取数据框偏移
    data_off_x, data_off_y = DATA_OFFSETS.get(city_name, (0, 0))
    
    # 特殊处理 Garching：数据框在城市名左边
    if city_name == "Garching":
        ax.annotate(data_text, xy=(label_x, label_y), xytext=(data_off_x, 0),
                    textcoords='offset points',
                    fontsize=8, color='#222222',
                    horizontalalignment='right',
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                             edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                    zorder=41)
    else:
        # 其他城市：数据框紧贴城市名框
        if label_y < y:  # 城市名在上方，数据在下方
            data_va = 'top'
            data_offset_y = -6
        else:  # 城市名在下方，数据在上方
            data_va = 'bottom'
            data_offset_y = 6
        
        ax.annotate(data_text, xy=(label_x, label_y), xytext=(label_offset_x, data_offset_y),
                    textcoords='offset points',
                    fontsize=8, color='#222222',
                    horizontalalignment=ha, verticalalignment=data_va,
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                             edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                    zorder=41)

# 移除坐标轴
ax.axis('off')
ax.set_xlim(0, img_width)
ax.set_ylim(img_height, 0)

plt.tight_layout(pad=0)

# 保存文件
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-final-v5.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site (2025 Jan vs 2026 Feb):")
for site, data in sorted(hc_data.items()):
    if site in SITE_COORDS and (data['Total_2026'] > 0 or data['Total_2025'] > 0):
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name}: {data['Total_2025']} → {data['Total_2026']}")
