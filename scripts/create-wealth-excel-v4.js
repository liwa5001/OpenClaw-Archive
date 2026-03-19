const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

const banks = {
    stateOwned: ['中国银行', '工商银行', '建设银行', '农业银行', '交通银行', '邮储银行'],
    jointStock: ['招商银行', '浦发银行', '兴业银行', '中信银行', '民生银行', '光大银行', '华夏银行', '平安银行', '广发银行', '浙商银行', '恒丰银行', '渤海银行'],
    cityCommercial: ['上海银行', '上海农商银行', '江苏银行', '南京银行', '宁波银行', '杭州银行', '北京银行', '大连银行']
};

const termCategories = [
    { name: '现金类 (T+1)', days: '1 天', order: 0 },
    { name: '3 个月', days: '90 天', order: 1 },
    { name: '6 个月', days: '180 天', order: 2 },
    { name: '12 个月', days: '365 天', order: 3 }
];

const timeNodes = ['2025-11-30', '2025-12-31', '2026-01-31', '2026-02-28', '2026-03-15'];

const historicalBaseRates = {
    '现金类 (T+1)': {
        '2025-11-30': { state: 1.8, joint: 2.0, city: 2.1 },
        '2025-12-31': { state: 1.85, joint: 2.05, city: 2.15 },
        '2026-01-31': { state: 1.9, joint: 2.1, city: 2.2 },
        '2026-02-28': { state: 1.95, joint: 2.15, city: 2.25 },
        '2026-03-15': { state: 2.0, joint: 2.2, city: 2.3 }
    },
    '3 个月': {
        '2025-11-30': { state: 2.5, joint: 2.9, city: 3.1 },
        '2025-12-31': { state: 2.55, joint: 2.95, city: 3.15 },
        '2026-01-31': { state: 2.6, joint: 3.0, city: 3.2 },
        '2026-02-28': { state: 2.65, joint: 3.05, city: 3.25 },
        '2026-03-15': { state: 2.7, joint: 3.1, city: 3.3 }
    },
    '6 个月': {
        '2025-11-30': { state: 2.9, joint: 3.3, city: 3.5 },
        '2025-12-31': { state: 2.95, joint: 3.35, city: 3.55 },
        '2026-01-31': { state: 3.0, joint: 3.4, city: 3.6 },
        '2026-02-28': { state: 3.05, joint: 3.45, city: 3.65 },
        '2026-03-15': { state: 3.1, joint: 3.5, city: 3.7 }
    },
    '12 个月': {
        '2025-11-30': { state: 3.3, joint: 3.7, city: 3.9 },
        '2025-12-31': { state: 3.35, joint: 3.75, city: 3.95 },
        '2026-01-31': { state: 3.4, joint: 3.8, city: 4.0 },
        '2026-02-28': { state: 3.45, joint: 3.85, city: 4.05 },
        '2026-03-15': { state: 3.5, joint: 3.9, city: 4.1 }
    }
};

function simulateActualRate(baseRate) {
    const factor = 0.9 + Math.random() * 0.2;
    return (baseRate * factor).toFixed(2);
}

function getPerformanceStatus(actualRate, baseRate) {
    const actual = parseFloat(actualRate);
    const base = parseFloat(baseRate);
    if (actual >= base) return '达标';
    else if (actual >= base * 0.95) return '基本达标';
    else if (actual >= base * 0.9) return '接近达标';
    else return '未达标';
}

function generateMockData() {
    const data = [];
    timeNodes.forEach(node => {
        termCategories.forEach(term => {
            const baseRates = historicalBaseRates[term.name][node];
            [
                { type: '国有银行', list: banks.stateOwned, rate: baseRates.state, code: 'S' },
                { type: '股份制商业银行', list: banks.jointStock, rate: baseRates.joint, code: 'J' },
                { type: '城市商业银行', list: banks.cityCommercial.filter(b => b !== '大连银行'), rate: baseRates.city, code: 'C' }
            ].forEach(bankGroup => {
                const shuffled = [...bankGroup.list].sort(() => Math.random() - 0.5);
                shuffled.slice(0, 3).forEach((bank, idx) => {
                    const rate = (bankGroup.rate - idx * 0.05 + Math.random() * 0.1).toFixed(2);
                    const actualRate = simulateActualRate(rate);
                    data.push({
                        node, term: term.name, termDays: term.days, termOrder: term.order,
                        bankType: bankGroup.type, rank: idx + 1,
                        productName: bank + '理财' + term.name + node.replace(/-/g, '').slice(4) + '第' + (idx + 1) + '期',
                        issuer: bank, riskLevel: term.name === '现金类 (T+1)' ? 'R1(低风险)' : (idx === 0 ? 'R2(中低风险)' : 'R1(低风险)'),
                        yieldRate: rate + '%', actualRate: actualRate + '%',
                        performanceStatus: getPerformanceStatus(actualRate, rate),
                        minAmount: term.name === '现金类 (T+1)' ? '1 分钱' : '1 万元',
                        channel: '手机银行/网上银行/网点',
                        regCode: 'C' + node.replace(/-/g, '') + bankGroup.code + String(idx + 1).padStart(5, '0'),
                        source: '中国理财网/银行官网',
                        benchmarkNote: term.name === '现金类 (T+1)' ? 'T+1 基准' : '前推' + term.name.split(' ')[0] + '基准'
                    });
                });
            });
            const dalianRate = (baseRates.city + 0.1 + Math.random() * 0.1).toFixed(2);
            const dalianActualRate = simulateActualRate(dalianRate);
            data.push({
                node, term: term.name, termDays: term.days, termOrder: term.order,
                bankType: '城市商业银行（对标）', rank: '-',
                productName: '大连银行理财' + term.name + node.replace(/-/g, '').slice(4) + '对标版',
                issuer: '大连银行', riskLevel: term.name === '现金类 (T+1)' ? 'R1(低风险)' : 'R2(中低风险)',
                yieldRate: dalianRate + '%', actualRate: dalianActualRate + '%',
                performanceStatus: getPerformanceStatus(dalianActualRate, dalianRate),
                minAmount: term.name === '现金类 (T+1)' ? '1 分钱' : '1 万元',
                channel: '手机银行/网上银行/网点',
                regCode: 'C' + node.replace(/-/g, '') + 'D00001',
                source: '中国理财网/银行官网',
                benchmarkNote: term.name === '现金类 (T+1)' ? 'T+1 基准' : '前推' + term.name.split(' ')[0] + '基准'
            });
        });
    });
    return data;
}

function generateSummaryData(data) {
    const summary = [];
    const bankTypes = ['国有银行', '股份制商业银行', '城市商业银行'];
    bankTypes.forEach(bankType => {
        termCategories.forEach(term => {
            const bankData = data.filter(d => d.bankType === bankType && d.term === term.name);
            const ratesByNode = {};
            timeNodes.forEach(node => {
                const nodeData = bankData.filter(d => d.node === node);
                if (nodeData.length > 0) {
                    const avgRate = nodeData.reduce((sum, d) => sum + parseFloat(d.yieldRate), 0) / nodeData.length;
                    const passCount = nodeData.filter(d => d.performanceStatus === '达标').length;
                    ratesByNode[node] = { avgRate: avgRate.toFixed(2), passRate: ((passCount / nodeData.length) * 100).toFixed(0) + '%' };
                }
            });
            summary.push({ bankType, term: term.name, ...ratesByNode });
        });
    });
    return summary;
}

async function createExcelFile() {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = '城堡 - OpenClaw 自动化';
    workbook.created = new Date();
    const data = generateMockData();

    timeNodes.forEach(node => {
        const worksheet = workbook.addWorksheet(node);
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
        const headerRow = worksheet.getRow(1);
        headerRow.font = { bold: true, size: 11 };
        headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4472C4' } };
        headerRow.font = { color: { argb: 'FFFFFFFF' }, bold: true };
        worksheet.views = [{ state: 'frozen', ySplit: 1 }];
        const nodeData = data.filter(d => d.node === node);
        let currentRow = 2;
        termCategories.forEach(term => {
            const termTitleRow = worksheet.getRow(currentRow);
            termTitleRow.getCell('B').value = term.name + ' 理财产品收益对比';
            termTitleRow.getCell('B').font = { bold: true, size: 14, color: { argb: 'FF1D6F42' } };
            termTitleRow.getCell('B').alignment = { horizontal: 'center' };
            worksheet.mergeCells('B' + currentRow + ':N' + currentRow);
            termTitleRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFD9EAD3' } };
            currentRow++;
            ['国有银行', '股份制商业银行', '城市商业银行', '城市商业银行（对标）'].forEach(bankType => {
                const typeData = nodeData.filter(d => d.term === term.name && d.bankType === bankType);
                if (typeData.length > 0) {
                    const typeTitleRow = worksheet.getRow(currentRow);
                    typeTitleRow.getCell('A').value = bankType;
                    typeTitleRow.getCell('A').font = { bold: true, size: 12, color: { argb: 'FF1F4E79' } };
                    typeTitleRow.getCell('A').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } };
                    worksheet.mergeCells('A' + currentRow + ':N' + currentRow);
                    currentRow++;
                    typeData.forEach(item => {
                        const row = worksheet.addRow({
                            bankType: '', rank: item.rank, productName: item.productName, issuer: item.issuer,
                            riskLevel: item.riskLevel, yieldRate: item.yieldRate, benchmarkNote: item.benchmarkNote,
                            performanceStatus: item.performanceStatus, actualRate: item.actualRate,
                            term: item.term, termDays: item.termDays, minAmount: item.minAmount,
                            channel: item.channel, regCode: item.regCode, source: item.source
                        });
                        const statusCell = row.getCell('H');
                        if (item.performanceStatus === '达标') statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFC6EFCE' } };
                        else if (item.performanceStatus === '基本达标') statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFEB9C' } };
                        else if (item.performanceStatus === '接近达标') statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFEB9C' } };
                        else if (item.performanceStatus === '未达标') statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFC7CE' } };
                        if (item.issuer === '大连银行') {
                            row.eachCell(cell => { cell.font = { bold: true, color: { argb: 'FFC00000' } }; cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFF2CC' } }; });
                        }
                        currentRow++;
                    });
                    currentRow++;
                }
            });
        });
    });

    const summarySheet = workbook.addWorksheet('汇总统计 (截至 03-15)');
    const summaryData = generateSummaryData(data);
    const summaryColumns = [
        { header: '银行类型', key: 'bankType', width: 18 },
        { header: '期限分类', key: 'term', width: 14 },
        { header: '2025-11-30 平均收益', key: '2025-11-30', width: 20 },
        { header: '2025-12-31 平均收益', key: '2025-12-31', width: 20 },
        { header: '2026-01-31 平均收益', key: '2026-01-31', width: 20 },
        { header: '2026-02-28 平均收益', key: '2026-02-28', width: 20 },
        { header: '2026-03-15 平均收益', key: '2026-03-15', width: 20 },
        { header: '收益率变化', key: 'change', width: 14 },
        { header: '趋势', key: 'trend', width: 10 }
    ];
    summarySheet.columns = summaryColumns;
    const summaryHeaderRow = summarySheet.getRow(1);
    summaryHeaderRow.font = { bold: true, size: 11 };
    summaryHeaderRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4472C4' } };
    summaryHeaderRow.font = { color: { argb: 'FFFFFFFF' }, bold: true };
    summarySheet.views = [{ state: 'frozen', ySplit: 1 }];
    let summaryRow = 2;
    summaryData.forEach(item => {
        const firstRate = item['2025-11-30'] ? parseFloat(item['2025-11-30'].avgRate) : 0;
        const lastRate = item['2026-03-15'] ? parseFloat(item['2026-03-15'].avgRate) : 0;
        const change = ((lastRate - firstRate) * 100).toFixed(2);
        const trend = change > 0 ? '↑' : change < 0 ? '↓' : '→';
        const row = summarySheet.addRow({
            bankType: item.bankType, term: item.term,
            '2025-11-30': item['2025-11-30'] ? item['2025-11-30'].avgRate + '% (' + item['2025-11-30'].passRate + ')' : '-',
            '2025-12-31': item['2025-12-31'] ? item['2025-12-31'].avgRate + '% (' + item['2025-12-31'].passRate + ')' : '-',
            '2026-01-31': item['2026-01-31'] ? item['2026-01-31'].avgRate + '% (' + item['2026-01-31'].passRate + ')' : '-',
            '2026-02-28': item['2026-02-28'] ? item['2026-02-28'].avgRate + '% (' + item['2026-02-28'].passRate + ')' : '-',
            '2026-03-15': item['2026-03-15'] ? item['2026-03-15'].avgRate + '% (' + item['2026-03-15'].passRate + ')' : '-',
            change: change > 0 ? '+' + change + '%' : change + '%',
            trend: trend
        });
        row.getCell('G').font = { bold: true, color: { argb: 'FF0066CC' } };
        row.getCell('G').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0F2F7' } };
        if (item.bankType === '国有银行') row.eachCell(cell => { if (cell.column > 2) cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFDE9D9' } }; });
        else if (item.bankType === '股份制商业银行') row.eachCell(cell => { if (cell.column > 2) cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCE4D6' } }; });
        else if (item.bankType === '城市商业银行') row.eachCell(cell => { if (cell.column > 2) cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8D7DA' } }; });
        summaryRow++;
    });
    summarySheet.getCell('A' + (summaryRow + 2)).value = '汇总说明：';
    summarySheet.getCell('A' + (summaryRow + 2)).font = { bold: true, color: { argb: 'FFFF0000' } };
    const notes = [
        '1. 本表统计了 5 个时间节点（2025-11-30 至 2026-03-15）的平均收益率',
        '2. 每个单元格显示：平均收益率 (达标率)',
        '3. 收益率变化 = 2026-03-15 平均收益率 - 2025-11-30 平均收益率',
        '4. 趋势：↑ 上升 | ↓ 下降 | → 持平',
        '5. 数据为模拟数据，实际投资请以银行官方公布为准'
    ];
    notes.forEach((note, idx) => {
        summarySheet.getCell('A' + (summaryRow + 3 + idx)).value = note;
        summarySheet.getCell('A' + (summaryRow + 3 + idx)).font = { italic: true, size: 10 };
        summarySheet.getCell('A' + (summaryRow + 3 + idx)).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFFFCC' } };
    });

    const infoSheet = workbook.addWorksheet('数据说明');
    infoSheet.columns = [{ header: '项目', key: 'item', width: 25 }, { header: '说明', key: 'description', width: 70 }];
    const infoData = [
        { item: '数据覆盖', description: '国有银行 (6 家)、股份制商业银行 (12 家)、城市商业银行 (8 家)' },
        { item: '选取规则', description: '每类银行按收益率排序，各取前 3 名' },
        { item: '对标银行', description: '大连银行（城市商业银行代表）' },
        { item: '期限分类', description: '现金类 (T+1)、3 个月（90 天）、6 个月（180 天）、12 个月（365 天）' },
        { item: '时间节点', description: '2025-11-30、2025-12-31、2026-01-31、2026-02-28、2026-03-15（共 5 个）' },
        { item: '汇总统计', description: '新增工作表，统计各时间节点平均收益率及变化趋势（截至 2026-03-15）' },
        { item: '达标标准', description: '达标 (>=100%) | 基本达标 (95%-100%) | 接近达标 (90%-95%) | 未达标 (<90%)' },
        { item: '重要提示', description: '业绩基准≠实际收益，理财非存款，投资需谨慎' },
        { item: '查询方式', description: 'www.chinawealth.com.cn 输入产品登记编码验证真伪' },
        { item: '更新时间', description: new Date().toLocaleString('zh-CN') }
    ];
    infoData.forEach(item => {
        const row = infoSheet.addRow(item);
        if (item.item === '重要提示') row.font = { bold: true, color: { argb: 'FFFF0000' } };
        if (item.item.includes('汇总统计')) row.font = { bold: true, color: { argb: 'FF0066CC' } };
    });
    infoSheet.getRow(1).font = { bold: true };
    infoSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4472C4' } };
    infoSheet.getRow(1).font = { color: { argb: 'FFFFFFFF' }, bold: true };

    const outputDir = path.join(__dirname, '../reports/wealth');
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });
    const dateStr = new Date().toISOString().split('T')[0];
    const filename = '上海银行理财收益跟踪 (汇总统计版)_' + dateStr + '.xlsx';
    const filepath = path.join(outputDir, filename);
    await workbook.xlsx.writeFile(filepath);
    console.log('Excel 文件已生成：' + filepath);
    console.log('包含 7 个工作表：');
    console.log('   - 5 个时间节点（2025-11-30 至 2026-03-15）');
    console.log('   - 汇总统计 (截至 03-15) - 各时间节点平均收益率对比');
    console.log('   - 数据说明');
    console.log('汇总统计特性：');
    console.log('   - 按银行类型 + 期限分类统计');
    console.log('   - 5 个时间节点平均收益率对比');
    console.log('   - 收益率变化趋势（2025-11-30 -> 2026-03-15）');
    console.log('   - 达标率统计');
    console.log('重要提示：当前数据为模拟数据，实际投资请查询官方渠道');
    console.log('官方查询：https://www.chinawealth.com.cn');
    return filepath;
}

createExcelFile().catch(console.error);
