#!/usr/bin/env python3
"""
交互式地图校准工具
点击地图来标定每个城市的精确位置
"""

import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import json

# 7 个城市需要标定
CITIES = [
    "Suzhou, China (中国苏州)",
    "Bangalore, India (印度班加罗尔)",
    "Queretaro, Mexico (墨西哥克雷塔罗)",
    "Garching, Germany (德国加兴)",
    "Novi, USA (美国密歇根)",
    "Lodz, Poland (波兰罗兹)",
    "Nagoya, Japan (日本名古屋)",
]

class MapCalibrator:
    def __init__(self, image_path):
        self.image_path = image_path
        self.points = {}
        self.current_city_idx = 0
        self.fig, self.ax = None, None
        
    def onclick(self, event):
        if event.xdata is None or event.ydata is None:
            return
            
        x, y = int(event.xdata), int(event.ydata)
        city = CITIES[self.current_city_idx]
        self.points[city] = (x, y)
        
        print(f"✅ {city}: ({x}, {y})")
        
        # 在图上标记
        self.ax.plot(x, y, 'bo', markersize=12)
        self.ax.annotate(f"{self.current_city_idx + 1}. {city.split('(')[0].strip()}", 
                        xy=(x, y), xytext=(x + 15, y - 10),
                        fontsize=9, color='#333333', weight='medium',
                        bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                                 edgecolor='#2E86DE', alpha=0.9))
        self.fig.canvas.draw()
        
        self.current_city_idx += 1
        
        if self.current_city_idx >= len(CITIES):
            print("\n✅ 所有城市标定完成！")
            print(f"📂 保存位置：{self.points}")
            
            # 保存标定结果
            with open('/workspace/logs/map-calibration-points.json', 'w') as f:
                json.dump(self.points, f, indent=2)
            print("💾 已保存到 logs/map-calibration-points.json")
            
            # 生成最终地图
            self.generate_final_map()
            return
        
        print(f"\n👉 下一个：{CITIES[self.current_city_idx]}")
        print("   请在地图上点击该城市的位置...\n")
    
    def generate_final_map(self):
        """使用标定的点生成最终地图"""
        import matplotlib.patches as patches
        
        img = mpimg.imread(self.image_path)
        img_height, img_width = img.shape[:2]
        
        fig, ax = plt.subplots(figsize=(16, 9), dpi=150)
        ax.imshow(img)
        
        MARKER_COLOR = "#2E86DE"
        MARKER_RADIUS = 8
        
        for city, (x, y) in self.points.items():
            city_name = city.split('(')[0].strip()
            
            # 阴影
            shadow = patches.Circle((x - 2, y + 2), MARKER_RADIUS, 
                                   color='#999999', alpha=0.4, zorder=1)
            ax.add_patch(shadow)
            
            # 标记点
            marker = patches.Circle((x, y), MARKER_RADIUS, 
                                   color=MARKER_COLOR, alpha=0.95, zorder=2)
            ax.add_patch(marker)
            
            # 光晕
            glow = patches.Circle((x, y), MARKER_RADIUS + 4, 
                                 color=MARKER_COLOR, alpha=0.15, zorder=0)
            ax.add_patch(glow)
            
            # 标签
            ax.annotate(city_name, xy=(x, y), xytext=(x + 15, y - 10),
                       fontsize=9, color='#333333', weight='medium',
                       bbox=dict(boxstyle='round,pad=0.4', facecolor='white', 
                                edgecolor='none', alpha=0.9))
        
        ax.axis('off')
        ax.set_xlim(0, img_width)
        ax.set_ylim(img_height, 0)
        plt.tight_layout(pad=0)
        
        output_path = '/Users/liwang/.openclaw/workspace/world-map-footprint-calibrated.png'
        plt.savefig(output_path, dpi=150, facecolor='#FFFFFF', edgecolor='none',
                   bbox_inches='tight', pad_inches=0)
        print(f"\n🎨 最终地图已保存：{output_path}")
    
    def run(self):
        img = mpimg.imread(self.image_path)
        
        self.fig, self.ax = plt.subplots(figsize=(16, 9))
        self.ax.imshow(img)
        self.ax.axis('off')
        
        print("=" * 60)
        print("🗺️  地图城市标定工具")
        print("=" * 60)
        print("\n请按顺序点击每个城市在地图上的正确位置：\n")
        print(f"👉 第 1 个：{CITIES[0]}")
        print("   点击地图标定位置...\n")
        
        self.cid = self.fig.canvas.mpl_connect('button_press_event', self.onclick)
        plt.tight_layout()
        plt.show()

# 运行校准工具
if __name__ == "__main__":
    calibrator = MapCalibrator('/Users/liwang/.openclaw/workspace/world-map-ppt-template-v2.png')
    calibrator.run()
