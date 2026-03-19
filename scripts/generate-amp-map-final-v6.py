#!/usr/bin/env python3
"""
生成 AMP HC 数据对比地图 - 最终版 v6
- 修复 Garching 位置
- 加上 Nagoya
- 数字框紧贴线条顶端
- Garching 数据放到左边
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
MARKER_RADIUS = 14

# 标签配置
# 格式：城市名 -> (引线 anchor 偏移 x, anchor 偏移 y, 标签框偏移 x, 标签框偏移 y)
LABEL_CONFIG = {
    # 亚洲
    "Suzhou": (0, -100, 0, -145),       # 正上方
    "Chengdu": (-100, 0, -150, 0),      # 正左
    "Bangalore": (0, 100, 0, 145),      # 正下方
    "Nagoya": (100, 100, 150, 145),     # 右下
    
    # 欧洲
    "Garching": (-100, 0, -150, 0),     # 正左
    "Lodz": (100, -100, 150, -145),     # 右上
    
    # 美洲
    "Novi": (-80, -80, -130, -125),     # 左上
    "Queretaro": (-100, 100, -150, 145), # 左下
}

# 绘制有数据的 Site
for site, data in hc_data.items():
    if site not in SITE_COORDS:
        print(f"⚠️  跳过：{site}")
        continue
    
    total_2025 = data['Total_2025']
    total_2026 = data['Total_2026']
    
    if total_2026 == 0 and total_2025 == 0:
        continue
    
    city_name, lat, lon = SITE_COORDS[site]
    x, y = mercator_to_pixel(lon, lat, img_width, img_height)
    
    print(f"📍 {city_name}: ({lat:.2f}, {lon:.2f}) -> 像素 ({x:.1f}, {y:.1f})")
    
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
    
    # 绘制引线
    line_x = [x, anchor_x]
    line_y = [y, anchor_y]
    ax.plot(line_x, line_y, '-', color=MARKER_COLOR, linewidth=1.5, alpha=0.6, zorder=35)
    
    # 城市名称标签
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
    
    # Garching 特殊处理：数据框在城市名左边
    if city_name == "Garching":
        ax.annotate(data_text, xy=(label_x, label_y), xytext=(-155, 0),
                    textcoords='offset points',
                    fontsize=8, color='#222222',
                    horizontalalignment='right',
                    bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                             edgecolor=MARKER_COLOR, linewidth=1, alpha=0.98),
                    zorder=41)
    else:
        # 其他城市：数据框紧贴城市名
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
output_path = '/Users/liwang/.openclaw/workspace/Temp/world-map-amp-hc-final-v6.png'
plt.savefig(output_path, dpi=200, facecolor='#FFFFFF', edgecolor='none',
            bbox_inches='tight', pad_inches=0.1)

print(f"\n✅ 地图生成完成：{output_path}")
print(f"\n📊 已标记 Site:")
for site, data in sorted(hc_data.items()):
    if site in SITE_COORDS and (data['Total_2026'] > 0 or data['Total_2025'] > 0):
        city_name, _, _ = SITE_COORDS[site]
        print(f"  • {city_name}: {data['Total_2025']} → {data['Total_2026']}")
