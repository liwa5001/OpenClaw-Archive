#!/usr/bin/env python3
"""
汇总每个 site 2025 年 1 月和 2026 年 2 月的 Internal 和 External HC 数据
"""

import pandas as pd
import os

# 切换到文件目录
os.chdir('/Users/liwang/projects/CA_AMP_Workshop_Report')

# 读取数据
file_name = '副本 AMP HC_CY25 &CY26.xlsx'
df_2025 = pd.read_excel(file_name, sheet_name='2025 Jan')
df_2026 = pd.read_excel(file_name, sheet_name='2026 Feb')

# 清理数据 - 填充 NaN 值
df_2025['Int/Ext'] = df_2025['Int/Ext'].fillna('Unknown')
df_2026['Int/Ext'] = df_2026['Int/Ext'].fillna('Unknown')
df_2025['Location'] = df_2025['Location'].fillna('Unknown')
df_2026['Location'] = df_2026['Location'].fillna('Unknown')

# 汇总 2025 Jan - 按 Location 和 Int/Ext 分组
summary_2025 = df_2025.groupby(['Location', 'Int/Ext'])['HC'].sum().unstack(fill_value=0)
summary_2025['Total'] = summary_2025.sum(axis=1)

# 汇总 2026 Feb - 按 Location 和 Int/Ext 分组
summary_2026 = df_2026.groupby(['Location', 'Int/Ext'])['HC'].sum().unstack(fill_value=0)
summary_2026['Total'] = summary_2026.sum(axis=1)

print("=" * 80)
print("📊 2025 年 1 月各 Site HC 汇总")
print("=" * 80)
print(summary_2025)

print("\n" + "=" * 80)
print("📊 2026 年 2 月各 Site HC 汇总")
print("=" * 80)
print(summary_2026)

# 合并两年数据
all_locations = sorted(set(summary_2025.index) | set(summary_2026.index))

print("\n" + "=" * 80)
print("📊 两年数据对比 (按 Location)")
print("=" * 80)

for loc in all_locations:
    if loc == 'Unknown' or pd.isna(loc):
        continue
    
    int_2025 = summary_2025.loc[loc, 'Internal'] if loc in summary_2025.index and 'Internal' in summary_2025.columns else 0
    ext_2025 = summary_2025.loc[loc, 'External'] if loc in summary_2025.index and 'External' in summary_2025.columns else 0
    total_2025 = int_2025 + ext_2025
    
    int_2026 = summary_2026.loc[loc, 'Internal'] if loc in summary_2026.index and 'Internal' in summary_2026.columns else 0
    ext_2026 = summary_2026.loc[loc, 'External'] if loc in summary_2026.index and 'External' in summary_2026.columns else 0
    total_2026 = int_2026 + ext_2026
    
    print(f"\n{loc}:")
    print(f"  2025 Jan: Internal={int_2025}, External={ext_2025}, Total={total_2025}")
    print(f"  2026 Feb: Internal={int_2026}, External={ext_2026}, Total={total_2026}")
    if total_2025 > 0:
        change = ((total_2026 - total_2025) / total_2025) * 100
        print(f"  变化：{total_2026 - total_2025:+d} ({change:+.1f}%)")

# 保存汇总数据到 CSV
summary_combined = {}
for loc in all_locations:
    if loc == 'Unknown' or pd.isna(loc):
        continue
    
    int_2025 = summary_2025.loc[loc, 'Internal'] if loc in summary_2025.index and 'Internal' in summary_2025.columns else 0
    ext_2025 = summary_2025.loc[loc, 'External'] if loc in summary_2025.index and 'External' in summary_2025.columns else 0
    int_2026 = summary_2026.loc[loc, 'Internal'] if loc in summary_2026.index and 'Internal' in summary_2026.columns else 0
    ext_2026 = summary_2026.loc[loc, 'External'] if loc in summary_2026.index and 'External' in summary_2026.columns else 0
    
    summary_combined[loc] = {
        'Internal_2025': int_2025,
        'External_2025': ext_2025,
        'Total_2025': int_2025 + ext_2025,
        'Internal_2026': int_2026,
        'External_2026': ext_2026,
        'Total_2026': int_2026 + ext_2026,
    }

summary_df = pd.DataFrame(summary_combined).T
summary_df.to_csv('/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary.csv')
print(f"\n✅ 汇总数据已保存到：/Users/liwang/.openclaw/workspace/Temp/amp-hc-summary.csv")
