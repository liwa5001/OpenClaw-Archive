#!/usr/bin/env python3
"""
汇总每个 site 2025 年 1 月和 2026 年 2 月的 Internal 和 External HC 数据
"""

import pandas as pd
import glob
import os

# 文件目录
data_dir = '/Users/liwang/projects/CA_AMP_Workshop_Report'
os.chdir(data_dir)

# 查找文件
files = [f for f in glob.glob("*AMP*HC*.xlsx") if not f.startswith('~$')]
if not files:
    print("❌ 未找到文件")
    exit(1)

file_path = os.path.abspath(files[0])
print(f"📂 读取文件：{file_path}")

# 读取数据
df_2025 = pd.read_excel(file_path, sheet_name='2025 Jan')
df_2026 = pd.read_excel(file_path, sheet_name='2026 Feb')

print(f"✅ 2025 Jan: {len(df_2025)} 行")
print(f"✅ 2026 Feb: {len(df_2026)} 行")

# 清理数据 - 填充 NaN 值
df_2025['Int/Ext'] = df_2025['Int/Ext'].fillna('Unknown')
df_2026['Int/Ext'] = df_2026['Int/Ext'].fillna('Unknown')
df_2025['Location'] = df_2025['Location'].fillna('Unknown')
df_2026['Location'] = df_2026['Location'].fillna('Unknown')

# 汇总 2025 Jan - 按 Location 和 Int/Ext 分组
summary_2025 = df_2025.groupby(['Location', 'Int/Ext'])['HC'].sum().unstack(fill_value=0)
if 'Internal' not in summary_2025.columns:
    summary_2025['Internal'] = 0
if 'External' not in summary_2025.columns:
    summary_2025['External'] = 0
summary_2025['Total'] = summary_2025['Internal'] + summary_2025['External']

# 汇总 2026 Feb - 按 Location 和 Int/Ext 分组
summary_2026 = df_2026.groupby(['Location', 'Int/Ext'])['HC'].sum().unstack(fill_value=0)
if 'Internal' not in summary_2026.columns:
    summary_2026['Internal'] = 0
if 'External' not in summary_2026.columns:
    summary_2026['External'] = 0
summary_2026['Total'] = summary_2026['Internal'] + summary_2026['External']

# 合并两年数据 - 转换为字符串避免排序错误
all_locations = sorted(set(str(x) for x in summary_2025.index) | set(str(x) for x in summary_2026.index))

# 构建汇总字典
summary_data = {}
for loc in all_locations:
    if loc == 'Unknown' or pd.isna(loc):
        continue
    
    int_2025 = summary_2025.loc[loc, 'Internal'] if loc in summary_2025.index else 0
    ext_2025 = summary_2025.loc[loc, 'External'] if loc in summary_2025.index else 0
    int_2026 = summary_2026.loc[loc, 'Internal'] if loc in summary_2026.index else 0
    ext_2026 = summary_2026.loc[loc, 'External'] if loc in summary_2026.index else 0
    
    summary_data[loc] = {
        'Internal_2025': int(int_2025),
        'External_2025': int(ext_2025),
        'Total_2025': int(int_2025 + ext_2025),
        'Internal_2026': int(int_2026),
        'External_2026': int(ext_2026),
        'Total_2026': int(int_2026 + ext_2026),
    }

# 打印结果
print("\n" + "=" * 80)
print("📊 各 Site HC 汇总 (2025 Jan vs 2026 Feb)")
print("=" * 80)

for loc, data in sorted(summary_data.items()):
    print(f"\n{loc}:")
    print(f"  2025 Jan: Internal={data['Internal_2025']}, External={data['External_2025']}, Total={data['Total_2025']}")
    print(f"  2026 Feb: Internal={data['Internal_2026']}, External={data['External_2026']}, Total={data['Total_2026']}")
    if data['Total_2025'] > 0:
        change = ((data['Total_2026'] - data['Total_2025']) / data['Total_2025']) * 100
        print(f"  变化：{data['Total_2026'] - data['Total_2025']:+d} ({change:+.1f}%)")

# 保存汇总数据到 CSV
summary_df = pd.DataFrame(summary_data).T
output_csv = '/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary.csv'
summary_df.to_csv(output_csv)
print(f"\n✅ 汇总数据已保存到：{output_csv}")

# 输出 JSON 格式供地图脚本使用
import json
output_json = '/Users/liwang/.openclaw/workspace/Temp/amp-hc-data.json'
with open(output_json, 'w', encoding='utf-8') as f:
    json.dump(summary_data, f, indent=2, ensure_ascii=False)
print(f"✅ JSON 数据已保存到：{output_json}")
