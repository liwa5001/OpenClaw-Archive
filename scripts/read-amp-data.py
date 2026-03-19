#!/usr/bin/env python3
"""
读取 AMP HC 数据，汇总每个 site 2025 年 1 月和 2026 年 2 月的 internal 和 external 数据
"""

import pandas as pd
import os

# 文件路径
file_path = '/Users/liwang/projects/CA_AMP_Workshop_Report/副本 AMP HC_CY25 &CY26.xlsx'

print(f"📂 读取文件：{file_path}")
print(f"📁 文件存在：{os.path.exists(file_path)}\n")

# 读取 Excel
xls = pd.ExcelFile(file_path)

print("📊 Excel 包含的 Sheets:")
for i, sheet in enumerate(xls.sheet_names):
    print(f"  {i+1}. {sheet}")

# 读取第一个 sheet 查看数据结构
if xls.sheet_names:
    first_sheet = xls.sheet_names[0]
    print(f"\n📄 读取 Sheet: {first_sheet}")
    df = pd.read_excel(file_path, sheet_name=first_sheet)
    
    print(f"\n📏 数据尺寸：{df.shape[0]} 行 × {df.shape[1]} 列")
    print(f"\n📋 列名:")
    for i, col in enumerate(df.columns):
        print(f"  {i+1}. {col}")
    
    print(f"\n🔍 前 5 行数据:")
    print(df.head())
