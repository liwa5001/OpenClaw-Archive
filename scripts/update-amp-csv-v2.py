#!/usr/bin/env python3
"""
更新 AMP HC CSV
- Shanghai 合并到 Suzhou
"""

import pandas as pd

# 读取 CSV
csv_path = '/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary-comparison-v2.csv'
df = pd.read_csv(csv_path)

print("📊 原始数据:")
print(df.to_string(index=False))

# 合并 Shanghai 到 Suzhou
if 'Shanghai' in df['Site'].values and 'Suzhou' in df['Site'].values:
    shanghai_row = df[df['Site'] == 'Shanghai'].iloc[0]
    suzhou_row = df[df['Site'] == 'Suzhou'].iloc[0].copy()
    
    # 合并数据
    for col in ['Internal_2025', 'External_2025', 'Total_2025', 
                'Internal_2026', 'External_2026', 'Total_2026', 'Change_Abs']:
        suzhou_row[col] += shanghai_row[col]
    
    # 重新计算百分比
    if suzhou_row['Total_2025'] > 0:
        suzhou_row['Change_Pct'] = round((suzhou_row['Change_Abs'] / suzhou_row['Total_2025']) * 100, 1)
    
    # 删除 Shanghai 行
    df = df[df['Site'] != 'Shanghai']
    
    # 更新 Suzhou 行
    df.loc[df['Site'] == 'Suzhou', :] = suzhou_row.values
    
    print("\n📍 已将 Shanghai 合并到 Suzhou")

print("\n📊 更新后数据:")
print(df.to_string(index=False))

# 保存 CSV
output_csv = '/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary-final.csv'
df.to_csv(output_csv, index=False, encoding='utf-8-sig')
print(f"\n✅ CSV 已保存：{output_csv}")
