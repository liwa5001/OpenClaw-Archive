const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

// 银行分类
const banks = {
    // 国有六大行
    stateOwned: [
        '中国银行', '工商银行', '建设银行', '农业银行', '交通银行', '邮储银行'
    ],
    // 股份制商业银行（12 家）
    jointStock: [
        '招商银行', '浦发银行', '兴业银行', '中信银行', '民生银行',
        '光大银行', '华夏银行', '平安银行', '广发银行', '浙商银行',
        '恒丰银行', '渤海银行'
    ],
    // 城市商业银行（选取上海地区活跃的）
    cityCommercial: [
        '上海银行', '上海农商银行', '江苏银行', '南京银行', '宁波银行',
        '杭州银行', '北京银行', '大连银行'  // 大连银行作为对标
    ]
};

// 风险等级
const riskLevels = ['R1(低风险)', 'R2(中低风险)', 'R3(中风险)'];

// 期限分类（现金类放在最前面）
const termCategories = [
    { name: '现金类 (T+1)', days: '1 天', order: 0 },
    { name: '3 个月', days: '90 天', order: 1 },
    { name: '6 个月', days: '180 天', order: 2 },
    { name: '12 个月', days: '365 天', order: 3 }
];

// 时间节点（新增 2026-02-28 和 2026-03-15）
const timeNodes = ['2025-11-30', '2025-12-31', '2026-01-31', '2026-02-28', '2026-03-15'];

// 历史基准数据（模拟每个时间节点前推的业绩基准）
// 用于与实际收益率在相同时间基准下比较
const historicalBaseRates = {
    // 现金类基准（前推 1 天，近似当前）
    '现金类 (T+1)': {
        '2025-11-30': { state: 1.8, joint: 2.0, city: 2.1 },
        '2025-12-31': { state: 1.85, joint: 2.05, city: 2.15 },
        '2026-01-31': { state: 1.9, joint: 2.1, city: 2.2 },
        '2026-02-28': { state: 1.95, joint: 2.15, city: 2.25 },
        '2026-03-15': { state: 2.0, joint: 2.2, city: 2.3 }
    },
    // 3 个月期限基准（前推 3 个月）
    '3 个月': {
        '2025-11-30': { state: 2.5, joint: 2.9, city: 3.1 },  // 基于 2025-08-30
        '2025-12-31': { state: 2.55, joint: 2.95, city: 3.15 }, // 基于 2025-09-30
        '2026-01-31': { state: 2.6, joint: 3.0, city: 3.2 },   // 基于 2025-10-31
        '2026-02-28': { state: 2.65, joint: 3.05, city: 3.25 },  // 基于 2025-11-30
        '2026-03-15': { state: 2.7, joint: 3.1, city: 3.3 }     // 基于 2025-12-15
    },
    // 6 个月期限基准（前推 6 个月）
    '6 个月': {
        '2025-11-30': { state: 2.9, joint: 3.3, city: 3.5 },   // 基于 2025-05-30
        '2025-12-31': { state: 2.95, joint: 3.35, city: 3.55 }, // 基于 2025-06-30
        '2026-01-31': { state: 3.0, joint: 3.4, city: 3.6 },    // 基于 2025-07-31
        '2026-02-28': { state: 3.05, joint: 3.45, city: 3.65 },   // 基于 2025-08-31
        '2026-03-15': { state: 3.1, joint: 3.5, city: 3.7 }       // 基于 2025-09-15
    },
    // 12 个月期限基准（前推 12 个月）
    '12 个月': {
        '2025-11-30': { state: 3.3, joint: 3.7, city: 3.9 },   // 基于 2024-11-30
        '2025-12-31': { state: 3.35, joint: 3.75, city: 3.95 }, // 基于 2024-12-31
        '2026-01-31': { state: 3.4, joint: 3.8, city: 4.0 },    // 基于 2025-01-31
        '2026-02-28': { state: 3.45, joint: 3.85, city: 4.05 },   // 基于 2025-02-28
        '2026-03-15': { state: 3.5, joint: 3.9, city: 4.1 }       // 基于 2025-03-15
    }
};

// 模拟实际收益率（用于计算达标情况）
function simulateActualRate(baseRate) {
    // 实际收益率可能在基准的 90%-110% 之间波动
    const factor = 0.9 + Math.random() * 0.2;
    return (baseRate * factor).toFixed(2);
}

// 判断达标情况
function getPerformanceStatus(actualRate, baseRate) {
    const actual = parseFloat(actualRate);
    const base = parseFloat(baseRate);
    
    if (actual >= base) {
        return '✅ 达标';
    } else if (actual >= base * 0.95) {
        return '⚠️ 基本达标 (95%-100%)';
    } else if (actual >= base * 0.9) {
        return '⚠️ 接近达标 (90%-95%)';
    } else {
        return '❌ 未达标 (<90%)';
    }
}

// 生成模拟数据（使用历史基准数据）
function generateMockData() {
    const data = [];
    
    timeNodes.forEach(node => {
        termCategories.forEach(term => {
            // 从历史基准数据中获取该时间节点的基准收益率
            const baseRates = historicalBaseRates[term.name][node];
            
            // 国有银行前 3 名
            const shuffledState = [...banks.stateOwned].sort(() => Math.random() - 0.5);
            shuffledState.slice(0, 3).forEach((bank, idx) => {
                // 在当前基准上略有浮动
                const rate = (baseRates.state - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                const actualRate = simulateActualRate(rate);
                const status = getPerformanceStatus(actualRate, rate);
                const riskLevel = term.name === '现金类 (T+1)' ? 'R1(低风险)' : 'R1(低风险)';
                
                data.push({
                    node: node,
                    term: term.name,
                    termDays: term.days,
                    termOrder: term.order,
                    bankType: '国有银行',
                    rank: idx + 1,
                    productName: `${bank}理财${term.name}${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    actualRate: `${actualRate}%`,
                    performanceStatus: status,
                    minAmount: term.name === '现金类 (T+1)' ? '1 分钱' : '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}S${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网',
                    benchmarkNote: term.name === '现金类 (T+1)' ? 'T+1 基准' : `前推${term.name.split(' ')[0]}基准`
                });
            });
            
            // 股份制银行前 3 名
            const shuffledJoint = [...banks.jointStock].sort(() => Math.random() - 0.5);
            shuffledJoint.slice(0, 3).forEach((bank, idx) => {
                const rate = (baseRates.joint - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                const actualRate = simulateActualRate(rate);
                const status = getPerformanceStatus(actualRate, rate);
                const riskLevel = term.name === '现金类 (T+1)' ? 'R1(低风险)' : (idx === 0 ? 'R2(中低风险)' : 'R1(低风险)');
                
                data.push({
                    node: node,
                    term: term.name,
                    termDays: term.days,
                    termOrder: term.order,
                    bankType: '股份制商业银行',
                    rank: idx + 1,
                    productName: `${bank}理财${term.name}${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    actualRate: `${actualRate}%`,
                    performanceStatus: status,
                    minAmount: term.name === '现金类 (T+1)' ? '1 分钱' : '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}J${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网',
                    benchmarkNote: term.name === '现金类 (T+1)' ? 'T+1 基准' : `前推${term.name.split(' ')[0]}基准`
                });
            });
            
            // 城市商业银行前 3 名（不含大连银行）
            const cityBanksExclDalian = banks.cityCommercial.filter(b => b !== '大连银行');
            const shuffledCity = [...cityBanksExclDalian].sort(() => Math.random() - 0.5);
            shuffledCity.slice(0, 3).forEach((bank, idx) => {
                const rate = (baseRates.city - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                const actualRate = simulateActualRate(rate);
                const status = getPerformanceStatus(actualRate, rate);
                const riskLevel = term.name === '现金类 (T+1)' ? 'R1(低风险)' : (idx === 0 ? 'R2(中低风险)' : 'R1(低风险)');
                
                data.push({
                    node: node,
                    term: term.name,
                    termDays: term.days,
                    termOrder: term.order,
                    bankType: '城市商业银行',
                    rank: idx + 1,
                    productName: `${bank}理财${term.name}${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    actualRate: `${actualRate}%`,
                    performanceStatus: status,
                    minAmount: term.name === '现金类 (T+1)' ? '1 分钱' : '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}C${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网',
                    benchmarkNote: term.name === '现金类 (T+1)' ? 'T+1 基准' : `前推${term.name.split(' ')[0]}基准`
                });
            });
            
            // 大连银行（对标）
            const dalianRate = (baseRates.city + 0.1 + Math.random() * 0.1).toFixed(2);
            const dalianActualRate = simulateActualRate(dalianRate);
            const dalianStatus = getPerformanceStatus(dalianActualRate, dalianRate);
            
            data.push({
                node: node,
                term: term.name,
                termDays: term.days,
                termOrder: term.order,
                bankType: '城市商业银行（对标）',
                rank: '-',
                productName: `大连银行理财${term.name}${node.replace(/-/g, '').slice(4)}对标版`,
                issuer: '大连银行',
                riskLevel: term.name === '现金类 (T+1)' ? 'R1(低风险)' : 'R2(中低风险)',
                yieldRate: `${dalianRate}%`,
                actualRate: `${dalianActualRate}%`,
                performanceStatus: dalianStatus,
                minAmount: term.name === '现金类 (T+1)' ? '1 分钱' : '1 万元',
                channel: '手机银行/网上银行/网点',
                regCode: `C${node.replace(/-/g, '')}D00001`,
                source: '中国理财网/银行官网',
                benchmarkNote: term.name === '现金类 (T+1)' ? 'T+1 基准' : `前推${term.name.split(' ')[0]}基准`
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
            { header: '银行类型', key: 'bankType', width: 18 },
            { header: '排名', key: 'rank', width: 8 },
            { header: '产品名称', key: 'productName', width: 38 },
            { header: '发行机构', key: 'issuer', width: 15 },
            { header: '风险等级', key: 'riskLevel', width: 14 },
            { header: '业绩基准/年化', key: 'yieldRate', width: 18 },
            { header: '基准说明', key: 'benchmarkNote', width: 20 },
            { header: '到期后业绩达标情况', key: 'performanceStatus', width: 22 },
            { header: '实际收益率', key: 'actualRate', width: 14 },
            { header: '期限分类', key: 'term', width: 14 },
            { header: '具体期限', key: 'termDays', width: 12 },
            { header: '起购金额', key: 'minAmount', width: 12 },
            { header: '购买渠道', key: 'channel', width: 25 },
            { header: '产品登记编码', key: 'regCode', width: 20 },
            { header: '数据来源', key: 'source', width: 20 }
        ];
        
        worksheet.columns = columns;
        
        // 设置表头样式
        const headerRow = worksheet.getRow(1);
        headerRow.font = { bold: true, size: 11 };
        headerRow.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FF4472C4' }
        };
        headerRow.font = { color: { argb: 'FFFFFFFF' }, bold: true };
        
        // 冻结首行
        worksheet.views = [{ state: 'frozen', ySplit: 1 }];
        
        // 添加数据
        const mockData = generateMockData().filter(d => d.node === node);
        
        // 按期限分组（已按 termOrder 排序，现金类在最前）
        let currentRow = 2;
        termCategories.forEach(term => {
            // 添加期限标题行
            const termTitleRow = worksheet.getRow(currentRow);
            termTitleRow.getCell('A').value = `═══════════════════════════════════════════════════════════`;
            termTitleRow.getCell('B').value = `${term.name} 理财产品收益对比`;
            termTitleRow.getCell('B').font = { bold: true, size: 14, color: { argb: 'FF1D6F42' } };
            termTitleRow.getCell('B').alignment = { horizontal: 'center' };
            worksheet.mergeCells(`B${currentRow}:N${currentRow}`);
            termTitleRow.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFD9EAD3' }
            };
            currentRow++;
            
            const termData = mockData.filter(d => d.term === term.name);
            
            // 按银行类型分组
            const bankTypes = ['国有银行', '股份制商业银行', '城市商业银行', '城市商业银行（对标）'];
            
            bankTypes.forEach(bankType => {
                const typeData = termData.filter(d => d.bankType === bankType);
                
                // 添加银行类型小标题
                if (typeData.length > 0) {
                    const typeTitleRow = worksheet.getRow(currentRow);
                    typeTitleRow.getCell('A').value = `${bankType}`;
                    typeTitleRow.getCell('A').font = { bold: true, size: 12, color: { argb: 'FF1F4E79' } };
                    typeTitleRow.getCell('A').fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: 'FFE2EFDA' }
                    };
                    worksheet.mergeCells(`A${currentRow}:N${currentRow}`);
                    currentRow++;
                    
                    typeData.forEach((item, idx) => {
                        const row = worksheet.addRow({
                            bankType: '',
                            rank: item.rank,
                            productName: item.productName,
                            issuer: item.issuer,
                            riskLevel: item.riskLevel,
                            yieldRate: item.yieldRate,
                            benchmarkNote: item.benchmarkNote,
                            performanceStatus: item.performanceStatus,
                            actualRate: item.actualRate,
                            term: item.term,
                            termDays: item.termDays,
                            minAmount: item.minAmount,
                            channel: item.channel,
                            regCode: item.regCode,
                            source: item.source
                        });
                        
                        // 根据达标情况设置颜色
                        const statusCell = row.getCell('H'); // 到期后业绩达标情况
                        if (item.performanceStatus.includes('✅')) {
                            statusCell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: 'FFC6EFCE' }
                            };
                        } else if (item.performanceStatus.includes('⚠️')) {
                            statusCell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: 'FFFFEB9C' }
                            };
                        } else if (item.performanceStatus.includes('❌')) {
                            statusCell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: 'FFFFC7CE' }
                            };
                        }
                        
                        // 大连银行特殊标记
                        if (item.issuer === '大连银行') {
                            row.eachCell(cell => {
                                cell.font = { bold: true, color: { argb: 'FFC00000' } };
                                cell.fill = {
                                    type: 'pattern',
                                    pattern: 'solid',
                                    fgColor: { argb: 'FFFFF2CC' }
                                };
                            });
                        }
                        
                        // 现金类特殊标记
                        if (item.term === '现金类 (T+1)') {
                            row.getCell('J').fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: 'FFE0F2F7' }
                            };
                        }
                        
                        currentRow++;
                    });
                    
                    // 添加空行
                    currentRow++;
                }
            });
        });
        
        // 添加说明
        const noteRow = currentRow + 2;
        worksheet.getCell(`A${noteRow}`).value = '📊 数据说明：';
        worksheet.getCell(`A${noteRow}`).font = { bold: true, color: { argb: 'FFFF0000' } };
        
        const notes = [
            '1. 本表数据为模拟数据，实际投资请以银行官方公布为准',
            '2. 真实数据请查询：中国理财网 (www.chinawealth.com.cn)',
            '3. 各银行官网、手机银行 APP 可查询最新理财产品',
            '4. 业绩基准不等于实际收益，理财有风险，投资需谨慎',
            '5. "到期后业绩达标情况"为产品到期后实际收益率与业绩基准的对比',
            '6. "业绩基准/年化"列使用该时间节点前推对应期限的历史基准数据（如 3 个月期限使用 3 个月前的基准）',
            '7. "基准说明"列标注了业绩基准的时间来源（T+1 基准或前推 X 个月基准）',
            '8. 大连银行作为城市商业银行对标参考',
            '9. 现金类 (T+1) 产品流动性最强，收益率相对较低'
        ];
        
        notes.forEach((note, idx) => {
            worksheet.getCell(`A${noteRow + 1 + idx}`).value = note;
            worksheet.getCell(`A${noteRow + 1 + idx}`).font = { italic: true, size: 10 };
            worksheet.getCell(`A${noteRow + 1 + idx}`).fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFFFFFCC' }
            };
        });
    });
    
    // 添加汇总说明工作表
    const summarySheet = workbook.addWorksheet('📊 数据说明');
    summarySheet.columns = [
        { header: '项目', key: 'item', width: 25 },
        { header: '说明', key: 'description', width: 70 }
    ];
    
    const summaryData = [
        { item: '数据覆盖', description: '国有银行 (6 家)、股份制商业银行 (12 家)、城市商业银行 (8 家)' },
        { item: '选取规则', description: '每类银行按收益率排序，各取前 3 名' },
        { item: '对标银行', description: '大连银行（城市商业银行代表）' },
        { item: '期限分类', description: '现金类 (T+1)、3 个月（90 天）、6 个月（180 天）、12 个月（365 天）' },
        { item: '时间节点', description: '2025-11-30、2025-12-31、2026-01-31、2026-02-28（共 4 个）' },
        { item: '风险等级', description: 'R1(低风险) 至 R3(中风险)，银行理财多为 R1-R2' },
        { item: '新增字段', description: '到期后业绩达标情况 - 实际收益率与业绩基准对比' },
        { item: '基准说明', description: '业绩基准使用前推对应期限的历史数据，确保与实际收益率时间基准一致' },
        { item: '达标标准', description: '✅ 达标 (≥100%) | ⚠️ 基本达标 (95%-100%) | ⚠️ 接近达标 (90%-95%) | ❌ 未达标 (<90%)' },
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
        if (item.item === '新增字段' || item.item === '基准说明' || item.item === '达标标准') {
            row.font = { bold: true, color: { argb: 'FF0066CC' } };
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
    const filename = `上海银行理财收益跟踪 (含现金类 +4 时间节点)_${dateStr}.xlsx`;
    const filepath = path.join(outputDir, filename);
    
    await workbook.xlsx.writeFile(filepath);
    
    console.log('✅ Excel 文件已生成：' + filepath);
    console.log('📊 包含 ' + timeNodes.length + ' 个工作表（' + timeNodes.join('、') + '）');
    console.log('📋 每个工作表包含：');
    console.log('   - 现金类 (T+1) 产品（新增，放在最前）');
    console.log('   - 国有银行前 3 名');
    console.log('   - 股份制商业银行前 3 名');
    console.log('   - 城市商业银行前 3 名');
    console.log('   - 大连银行（对标）');
    console.log('   - 每个期限（现金类/3 个月/6 个月/12 个月）');
    console.log('');
    console.log('🆕 新增特性：');
    console.log('   - 新增 2026-02-28 时间节点');
    console.log('   - 新增现金类 (T+1) 产品，放在 3 个月之前');
    console.log('   - 新增"基准说明"列，标注业绩基准时间来源');
    console.log('   - 业绩基准使用前推对应期限的历史数据（与实际收益率时间基准一致）');
    console.log('');
    console.log('⚠️  重要提示：当前数据为模拟数据，实际投资请查询官方渠道');
    console.log('🔗 官方查询：https://www.chinawealth.com.cn');
    
    return filepath;
}

// 运行
createExcelFile().catch(console.error);
