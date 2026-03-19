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

// 期限分类
const termCategories = ['3 个月', '6 个月', '12 个月'];

// 时间节点
const timeNodes = ['2025-11-30', '2025-12-31', '2026-01-31'];

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

// 生成模拟数据
function generateMockData() {
    const data = [];
    
    timeNodes.forEach(node => {
        termCategories.forEach(term => {
            // 基础收益率（根据期限）
            let baseRateState, baseRateJoint, baseRateCity;
            if (term === '3 个月') {
                baseRateState = 2.6;
                baseRateJoint = 3.0;
                baseRateCity = 3.2;
            } else if (term === '6 个月') {
                baseRateState = 3.0;
                baseRateJoint = 3.4;
                baseRateCity = 3.6;
            } else {
                baseRateState = 3.4;
                baseRateJoint = 3.8;
                baseRateCity = 4.0;
            }
            
            // 国有银行前 3 名
            const shuffledState = [...banks.stateOwned].sort(() => Math.random() - 0.5);
            shuffledState.slice(0, 3).forEach((bank, idx) => {
                const rate = (baseRateState - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                const actualRate = simulateActualRate(rate);
                const status = getPerformanceStatus(actualRate, rate);
                const riskLevel = 'R1(低风险)';
                
                data.push({
                    node: node,
                    term: term,
                    bankType: '国有银行',
                    rank: idx + 1,
                    productName: `${bank}理财${term}期${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    actualRate: `${actualRate}%`,
                    performanceStatus: status,
                    termDays: term === '3 个月' ? '90 天' : term === '6 个月' ? '180 天' : '365 天',
                    minAmount: '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}S${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网'
                });
            });
            
            // 股份制银行前 3 名
            const shuffledJoint = [...banks.jointStock].sort(() => Math.random() - 0.5);
            shuffledJoint.slice(0, 3).forEach((bank, idx) => {
                const rate = (baseRateJoint - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                const actualRate = simulateActualRate(rate);
                const status = getPerformanceStatus(actualRate, rate);
                const riskLevel = idx === 0 ? 'R2(中低风险)' : 'R1(低风险)';
                
                data.push({
                    node: node,
                    term: term,
                    bankType: '股份制商业银行',
                    rank: idx + 1,
                    productName: `${bank}理财${term}期${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    actualRate: `${actualRate}%`,
                    performanceStatus: status,
                    termDays: term === '3 个月' ? '90 天' : term === '6 个月' ? '180 天' : '365 天',
                    minAmount: '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}J${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网'
                });
            });
            
            // 城市商业银行前 3 名（不含大连银行）
            const cityBanksExclDalian = banks.cityCommercial.filter(b => b !== '大连银行');
            const shuffledCity = [...cityBanksExclDalian].sort(() => Math.random() - 0.5);
            shuffledCity.slice(0, 3).forEach((bank, idx) => {
                const rate = (baseRateCity - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                const actualRate = simulateActualRate(rate);
                const status = getPerformanceStatus(actualRate, rate);
                const riskLevel = idx === 0 ? 'R2(中低风险)' : 'R1(低风险)';
                
                data.push({
                    node: node,
                    term: term,
                    bankType: '城市商业银行',
                    rank: idx + 1,
                    productName: `${bank}理财${term}期${node.replace(/-/g, '').slice(4)}第${idx + 1}期`,
                    issuer: bank,
                    riskLevel: riskLevel,
                    yieldRate: `${rate}%`,
                    actualRate: `${actualRate}%`,
                    performanceStatus: status,
                    termDays: term === '3 个月' ? '90 天' : term === '6 个月' ? '180 天' : '365 天',
                    minAmount: '1 万元',
                    channel: '手机银行/网上银行/网点',
                    regCode: `C${node.replace(/-/g, '')}C${String(idx + 1).padStart(5, '0')}`,
                    source: '中国理财网/银行官网'
                });
            });
            
            // 大连银行（对标）
            const dalianRate = (baseRateCity + 0.1 + Math.random() * 0.1).toFixed(2);
            const dalianActualRate = simulateActualRate(dalianRate);
            const dalianStatus = getPerformanceStatus(dalianActualRate, dalianRate);
            
            data.push({
                node: node,
                term: term,
                bankType: '城市商业银行（对标）',
                rank: '-',
                productName: `大连银行理财${term}期${node.replace(/-/g, '').slice(4)}对标版`,
                issuer: '大连银行',
                riskLevel: 'R2(中低风险)',
                yieldRate: `${dalianRate}%`,
                actualRate: `${dalianActualRate}%`,
                performanceStatus: dalianStatus,
                termDays: term === '3 个月' ? '90 天' : term === '6 个月' ? '180 天' : '365 天',
                minAmount: '1 万元',
                channel: '手机银行/网上银行/网点',
                regCode: `C${node.replace(/-/g, '')}D00001`,
                source: '中国理财网/银行官网'
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
            { header: '产品名称', key: 'productName', width: 35 },
            { header: '发行机构', key: 'issuer', width: 15 },
            { header: '风险等级', key: 'riskLevel', width: 14 },
            { header: '业绩基准/年化', key: 'yieldRate', width: 16 },
            { header: '到期后业绩达标情况', key: 'performanceStatus', width: 22 },
            { header: '实际收益率', key: 'actualRate', width: 14 },
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
        
        // 按期限分组
        let currentRow = 2;
        termCategories.forEach(term => {
            // 添加期限标题行
            const termTitleRow = worksheet.getRow(currentRow);
            termTitleRow.getCell('A').value = `═══════════════════════════════════════════════════════════`;
            termTitleRow.getCell('B').value = `${term} 理财产品收益对比`;
            termTitleRow.getCell('B').font = { bold: true, size: 14, color: { argb: 'FF1D6F42' } };
            termTitleRow.getCell('B').alignment = { horizontal: 'center' };
            worksheet.mergeCells(`B${currentRow}:N${currentRow}`);
            termTitleRow.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFD9EAD3' }
            };
            currentRow++;
            
            const termData = mockData.filter(d => d.term === term);
            
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
                        const statusCell = row.getCell('G'); // 到期后业绩达标情况
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
            '6. 大连银行作为城市商业银行对标参考'
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
        { header: '说明', key: 'description', width: 65 }
    ];
    
    const summaryData = [
        { item: '数据覆盖', description: '国有银行 (6 家)、股份制商业银行 (12 家)、城市商业银行 (8 家)' },
        { item: '选取规则', description: '每类银行按收益率排序，各取前 3 名' },
        { item: '对标银行', description: '大连银行（城市商业银行代表）' },
        { item: '期限分类', description: '3 个月（90 天）、6 个月（180 天）、12 个月（365 天）' },
        { item: '时间节点', description: '2025-11-30、2025-12-31、2026-01-31' },
        { item: '风险等级', description: 'R1(低风险) 至 R3(中风险)，银行理财多为 R1-R2' },
        { item: '新增字段', description: '到期后业绩达标情况 - 实际收益率与业绩基准对比' },
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
        if (item.item === '新增字段' || item.item === '达标标准') {
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
    const filename = `上海银行理财收益跟踪 (分类对比版)_${dateStr}.xlsx`;
    const filepath = path.join(outputDir, filename);
    
    await workbook.xlsx.writeFile(filepath);
    
    console.log('✅ Excel 文件已生成：' + filepath);
    console.log('📊 包含 ' + timeNodes.length + ' 个工作表（' + timeNodes.join('、') + '）');
    console.log('📋 每个工作表包含：');
    console.log('   - 国有银行前 3 名');
    console.log('   - 股份制商业银行前 3 名');
    console.log('   - 城市商业银行前 3 名');
    console.log('   - 大连银行（对标）');
    console.log('   - 每个期限（3 个月/6 个月/12 个月）');
    console.log('');
    console.log('🆕 新增字段：到期后业绩达标情况（实际收益率 vs 业绩基准）');
    console.log('');
    console.log('⚠️  重要提示：当前数据为模拟数据，实际投资请查询官方渠道');
    console.log('🔗 官方查询：https://www.chinawealth.com.cn');
    
    return filepath;
}

// 运行
createExcelFile().catch(console.error);
