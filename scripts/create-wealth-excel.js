const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

// 上海地区主要银行列表
const banks = [
    '中国银行', '工商银行', '建设银行', '农业银行', '交通银行',
    '招商银行', '浦发银行', '兴业银行', '中信银行', '民生银行',
    '光大银行', '华夏银行', '平安银行', '广发银行', '浙商银行',
    '恒丰银行', '渤海银行', '上海银行', '上海农商银行', '江苏银行',
    '南京银行', '宁波银行', '杭州银行', '北京银行'
];

// 风险等级
const riskLevels = ['R1(低风险)', 'R2(中低风险)', 'R3(中风险)', 'R4(中高风险)', 'R5(高风险)'];

// 期限分类
const termCategories = ['3 个月', '6 个月', '12 个月'];

// 时间节点
const timeNodes = ['2025-11-30', '2025-12-31', '2026-01-31'];

// 模拟数据（实际使用需要替换为真实数据）
function generateMockData() {
    const data = [];
    
    timeNodes.forEach(node => {
        termCategories.forEach(term => {
            // 为每个期限生成 5 家收益最高的银行（模拟）
            const shuffled = [...banks].sort(() => Math.random() - 0.5);
            const top5 = shuffled.slice(0, 5);
            
            top5.forEach((bank, idx) => {
                // 模拟收益率（3 个月约 2.5-3.5%, 6 个月约 3.0-4.0%, 12 个月约 3.5-4.5%）
                let baseRate;
                if (term === '3 个月') baseRate = 2.8;
                else if (term === '6 个月') baseRate = 3.3;
                else baseRate = 3.8;
                
                const rate = (baseRate + Math.random() * 0.5 - idx * 0.1).toFixed(2);
                const riskLevel = riskLevels[Math.floor(Math.random() * 2)]; // 主要 R1/R2
                
                data.push({
                    node: node,
                    term: term,
                    rank: idx + 1,
                    productName: `${bank}理财${term}期${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    termDays: term === '3 个月' ? '90 天' : term === '6 个月' ? '180 天' : '365 天',
                    minAmount: '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网'
                });
            });
        });
    });
    
    return data;
}

async function createExcelFile() {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = '城堡 - OpenClaw 自动化';
    workbook.created = new Date();
    
    // 为每个时间节点创建工作表
    timeNodes.forEach(node => {
        const worksheet = workbook.addWorksheet(node);
        
        // 设置列（使用中文表头）
        const columns = [
            { header: '排名', key: 'rank', width: 8 },
            { header: '产品名称', key: 'productName', width: 35 },
            { header: '发行机构', key: 'issuer', width: 15 },
            { header: '风险等级', key: 'riskLevel', width: 12 },
            { header: '业绩基准/年化', key: 'yieldRate', width: 15 },
            { header: '期限分类', key: 'term', width: 12 },
            { header: '具体期限', key: 'termDays', width: 12 },
            { header: '起购金额', key: 'minAmount', width: 12 },
            { header: '购买渠道', key: 'channel', width: 25 },
            { header: '产品登记编码', key: 'regCode', width: 20 },
            { header: '数据来源', key: 'source', width: 20 }
        ];
        
        worksheet.columns = columns;
        
        // 设置表头样式
        const headerRow = worksheet.getRow(1);
        headerRow.font = { bold: true, size: 12 };
        headerRow.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FF4472C4' }
        };
        headerRow.font = { color: { argb: 'FFFFFFFF' }, bold: true };
        
        // 添加数据
        const mockData = generateMockData().filter(d => d.node === node);
        
        // 按期限分组
        termCategories.forEach(term => {
            const termData = mockData.filter(d => d.term === term);
            
            termData.forEach((item, idx) => {
                const row = worksheet.addRow({
                    rank: item.rank,
                    productName: item.productName,
                    issuer: item.issuer,
                    riskLevel: item.riskLevel,
                    yieldRate: item.yieldRate,
                    term: item.term,
                    termDays: item.termDays,
                    minAmount: item.minAmount,
                    channel: item.channel,
                    regCode: item.regCode,
                    source: item.source
                });
                
                // 交替行颜色
                if ((idx + 1) % 2 === 0) {
                    row.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: 'FFF2F2F2' }
                    };
                }
            });
            
            // 添加空行分隔
            worksheet.addRow({});
        });
        
        // 添加说明
        const lastRow = worksheet.lastRow.number + 2;
        worksheet.getCell(`A${lastRow}`).value = '数据说明：';
        worksheet.getCell(`A${lastRow}`).font = { bold: true, color: { argb: 'FFFF0000' } };
        
        worksheet.getCell(`A${lastRow + 1}`).value = '1. 本表数据为模拟数据，实际投资请以银行官方公布为准';
        worksheet.getCell(`A${lastRow + 2}`).value = '2. 真实数据请查询：中国理财网 (www.chinawealth.com.cn)';
        worksheet.getCell(`A${lastRow + 3}`).value = '3. 各银行官网、手机银行 APP 可查询最新理财产品';
        worksheet.getCell(`A${lastRow + 4}`).value = '4. 业绩基准不等于实际收益，理财有风险，投资需谨慎';
        
        for (let i = lastRow; i <= lastRow + 4; i++) {
            worksheet.getCell(`A${i}`).font = { italic: true, size: 10 };
            worksheet.getCell(`A${i}`).fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFFFFFCC' }
            };
        }
    });
    
    // 添加汇总说明工作表
    const summarySheet = workbook.addWorksheet('📊 数据说明');
    summarySheet.columns = [
        { header: '项目', key: 'item', width: 20 },
        { header: '说明', key: 'description', width: 60 }
    ];
    
    const summaryData = [
        { item: '数据覆盖', description: '上海地区 24 家主要银行（国有大行、股份制、城商行、农商行）' },
        { item: '期限分类', description: '3 个月（90 天）、6 个月（180 天）、12 个月（365 天）' },
        { item: '时间节点', description: '2025-11-30、2025-12-31、2026-01-31' },
        { item: '排名规则', description: '按业绩基准/年化收益率从高到低排序，每个期限取前 5 名' },
        { item: '风险等级', description: 'R1(低风险) 至 R5(高风险)，银行理财多为 R1-R2' },
        { item: '数据来源', description: '中国理财网、各银行官网、手机银行 APP' },
        { item: '重要提示', description: '业绩基准≠实际收益，理财非存款，投资需谨慎' },
        { item: '查询方式', description: 'www.chinawealth.com.cn 输入产品登记编码验证真伪' },
        { item: '更新时间', description: new Date().toLocaleString('zh-CN') }
    ];
    
    summaryData.forEach(item => {
        const row = summarySheet.addRow(item);
        if (item.item === '重要提示') {
            row.font = { bold: true, color: { argb: 'FFFF0000' } };
        }
    });
    
    summarySheet.getRow(1).font = { bold: true };
    summarySheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF4472C4' }
    };
    summarySheet.getRow(1).font = { color: { argb: 'FFFFFFFF' }, bold: true };
    
    // 保存文件
    const outputDir = path.join(__dirname, '../reports/wealth');
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    
    const dateStr = new Date().toISOString().split('T')[0];
    const filename = `上海银行理财收益跟踪_${dateStr}.xlsx`;
    const filepath = path.join(outputDir, filename);
    
    await workbook.xlsx.writeFile(filepath);
    
    console.log('✅ Excel 文件已生成：' + filepath);
    console.log('📊 包含 ' + timeNodes.length + ' 个工作表（' + timeNodes.join('、') + '）');
    console.log('📋 每个工作表包含 ' + termCategories.length + ' 个期限分类，每个期限前 5 名银行');
    console.log('');
    console.log('⚠️  重要提示：当前数据为模拟数据，实际投资请查询官方渠道');
    console.log('🔗 官方查询：https://www.chinawealth.com.cn');
    
    return filepath;
}

// 运行
createExcelFile().catch(console.error);
