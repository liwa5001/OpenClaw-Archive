#!/usr/bin/env python3
"""
读取 AMP HC 数据
"""

import pandas as pd
import os

# 切换到文件目录
os.chdir('/Users/liwang/projects/CA_AMP_Workshop_Report')

# 查找文件
import glob
files = [f for f in glob.glob("*AMP*HC*.xlsx") if not f.startswith('~$')]
print(f"找到的文件：{files}")

if not files:
    print("❌ 未找到文件")
    exit(1)

file_name = files[0]
print(f"读取：{file_name}")

# 读取数据
df_2025 = pd.read_excel(file_name, sheet_name='2025 Jan')
df_2026 = pd.read_excel(file_name, sheet_name='2026 Feb')

print("\n" + "=" * 60)
print("📊 2025 Jan 数据结构")
print("=" * 60)
print(f"列名：{list(df_2025.columns)}")
print(f"尺寸：{df_2025.shape}")
print("\n前 5 行:")
print(df_2025.head())

print("\n" + "=" * 60)
print("📊 2026 Feb 数据结构")
print("=" * 60)
print(f"列名：{list(df_2026.columns)}")
print(f"尺寸：{df_2026.shape}")
print("\n前 5 行:")
print(df_2026.head())

# 查看 Site 列
print("\n" + "=" * 60)
print("📍 Site 信息")
print("=" * 60)
# 查找包含 Site 或 Location 的列
for col in df_2025.columns:
    if 'site' in str(col).lower() or 'location' in str(col).lower() or 'city' in str(col).lower():
        print(f"\n列 '{col}' 的唯一值:")
        print(df_2025[col].unique()[:20])
