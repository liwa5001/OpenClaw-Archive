#!/usr/bin/env python3
"""
上海银行理财收益数据抓取脚本
数据来源：中国理财网 (www.chinawealth.com.cn)

依赖安装：
pip install selenium pandas openpyxl webdriver-manager

使用方法：
python scrape-wealth-data.py

注意：
1. 本脚本仅供参考，实际使用需要根据网站结构调整
2. 请遵守网站 robots.txt 和使用条款
3. 建议控制抓取频率，避免对服务器造成压力
"""

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait, Select
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import pandas as pd
import time
from datetime import datetime

# 上海地区主要银行
BANKS = [
    '中国银行', '工商银行', '建设银行', '农业银行', '交通银行',
    '招商银行', '浦发银行', '兴业银行', '中信银行', '民生银行',
    '光大银行', '华夏银行', '平安银行', '广发银行', '浙商银行',
    '恒丰银行', '渤海银行', '上海银行', '上海农商银行', '江苏银行',
    '南京银行', '宁波银行', '杭州银行', '北京银行'
]

# 期限映射
TERM_MAP = {
    '3 个月': (80, 100),  # 天数范围
    '6 个月': (170, 190),
    '12 个月': (350, 380)
}

# 时间节点
TIME_NODES = ['2025-11-30', '2025-12-31', '2026-01-31']


def setup_driver():
    """配置 Chrome 驱动"""
    chrome_options = Options()
    chrome_options.add_argument('--headless')  # 无头模式
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--window-size=1920,1080')
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)
    return driver


def scrape_product_data(driver, bank_name, term_category):
    """
    抓取单个银行某期限的理财产品数据
    
    Args:
        driver: Selenium WebDriver
        bank_name: 银行名称
        term_category: 期限分类（3 个月/6 个月/12 个月）
    
    Returns:
        list: 产品数据列表
    """
    products = []
    
    try:
        # 访问中国理财网产品查询页面
        driver.get('https://www.chinawealth.com.cn/lcweb/management/proScreen')
        time.sleep(3)
        
        # 等待页面加载
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CLASS_NAME, 'search-form'))
        )
        
        # 选择发行机构
        bank_select = driver.find_element(By.ID, 'issuerSelect')
        Select(bank_select).select_by_visible_text(bank_name)
        
        # 选择期限范围
        min_days, max_days = TERM_MAP[term_category]
        driver.find_element(By.ID, 'termMin').send_keys(str(min_days))
        driver.find_element(By.ID, 'termMax').send_keys(str(max_days))
        
        # 选择销售地区（上海）
        # driver.find_element(By.ID, 'salesArea').send_keys('上海')
        
        # 点击查询
        driver.find_element(By.ID, 'searchBtn').click()
        time.sleep(3)
        
        # 按收益率排序
        # yield_sort = driver.find_element(By.XPATH, '//th[contains(text(), "业绩基准")]')
        # yield_sort.click()
        # time.sleep(2)
        
        # 抓取产品数据
        rows = driver.find_elements(By.CSS_SELECTOR, '.product-list tbody tr')
        
        for idx, row in enumerate(rows[:5]):  # 只取前 5 名
            try:
                cols = row.find_elements(By.TAG_NAME, 'td')
                if len(cols) >= 10:
                    product = {
                        '排名': idx + 1,
                        '产品名称': cols[0].text,
                        '发行机构': cols[1].text,
                        '风险等级': cols[2].text,
                        '业绩基准_年化': cols[3].text,
                        '期限分类': term_category,
                        '具体期限': cols[4].text,
                        '起购金额': cols[5].text,
                        '购买渠道': cols[6].text,
                        '产品登记编码': cols[7].text,
                        '数据来源': '中国理财网',
                        '抓取时间': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    }
                    products.append(product)
            except Exception as e:
                print(f"解析行失败：{e}")
                continue
                
    except Exception as e:
        print(f"抓取 {bank_name} {term_category} 数据失败：{e}")
    
    return products


def main():
    """主函数"""
    print("🚀 开始抓取上海银行理财收益数据...")
    print(f"📊 覆盖银行：{len(BANKS)} 家")
    print(f"📅 时间节点：{TIME_NODES}")
    print(f"⏱️  期限分类：{list(TERM_MAP.keys())}")
    print()
    
    driver = setup_driver()
    all_data = []
    
    try:
        # 为每个时间节点抓取数据
        for node in TIME_NODES:
            print(f"📅 处理时间节点：{node}")
            
            # 为每家银行抓取数据
            for bank in BANKS:
                print(f"  🏦 {bank}...", end=' ')
                
                # 为每个期限抓取数据
                for term in TERM_MAP.keys():
                    products = scrape_product_data(driver, bank, term)
                    for p in products:
                        p['时间节点'] = node
                    all_data.extend(products)
                    
                    print(f"{term}({len(products)}条)", end=' ')
                
                print()
                time.sleep(2)  # 避免请求过快
            
            print()
        
        # 保存为 Excel
        if all_data:
            df = pd.DataFrame(all_data)
            
            # 创建 Excel writer
            output_file = f'上海银行理财收益跟踪_{datetime.now().strftime("%Y-%m-%d")}.xlsx'
            
            with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
                # 为每个时间节点创建单独的工作表
                for node in TIME_NODES:
                    node_df = df[df['时间节点'] == node]
                    sheet_name = node.replace('-', '.')
                    node_df.to_excel(writer, sheet_name=sheet_name, index=False)
                    
                    # 调整列宽
                    worksheet = writer.sheets[sheet_name]
                    for column in worksheet.columns:
                        max_length = 0
                        column = [cell for cell in column]
                        for cell in column:
                            try:
                                if len(str(cell.value)) > max_length:
                                    max_length = len(str(cell.value))
                            except:
                                pass
                        adjusted_width = min(max_length + 2, 50)
                        worksheet.column_dimensions[column[0].column_letter].width = adjusted_width
                
                # 创建说明工作表
                summary_df = pd.DataFrame({
                    '项目': ['数据覆盖', '期限分类', '时间节点', '排名规则', '数据来源', '抓取时间'],
                    '说明': [
                        f'{len(BANKS)} 家上海地区银行',
                        '3 个月/6 个月/12 个月',
                        ', '.join(TIME_NODES),
                        '按业绩基准/年化降序，取前 5 名',
                        '中国理财网 (www.chinawealth.com.cn)',
                        datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    ]
                })
                summary_df.to_excel(writer, sheet_name='📊 数据说明', index=False)
            
            print(f"✅ 数据已保存：{output_file}")
            print(f"📊 共抓取 {len(all_data)} 条产品记录")
        else:
            print("⚠️  未抓取到数据，请检查网络连接或网站结构是否变化")
    
    finally:
        driver.quit()
        print("👋 浏览器已关闭")


if __name__ == '__main__':
    main()
