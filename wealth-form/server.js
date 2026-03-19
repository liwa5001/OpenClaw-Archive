const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8898;
const DATA_DIR = path.join(__dirname, '../daily-output/wealth/weekly-stats');

// 确保数据目录存在
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

const server = http.createServer((req, res) => {
    // CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // 处理静态文件
    if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
        const filePath = path.join(__dirname, 'index.html');
        fs.readFile(filePath, (err, content) => {
            if (err) {
                res.writeHead(500);
                res.end('服务器错误');
                return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
            res.end(content);
        });
        return;
    }
    
    // 处理 API 请求
    if (req.method === 'POST' && req.url === '/api/save') {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                
                // 生成年份和周数目录
                const year = data.year || new Date().getFullYear();
                const weekNum = data.weekNum || getWeekNumber(new Date(data.date));
                const yearDir = path.join(DATA_DIR, year.toString());
                
                if (!fs.existsSync(yearDir)) {
                    fs.mkdirSync(yearDir, { recursive: true });
                }
                
                // 生成文件名
                const fileName = `W${weekNum}-wealth-stats.md`;
                const filePath = path.join(yearDir, fileName);
                
                // 生成 Markdown 报告
                const report = generateWealthReport(data);
                
                // 保存文件
                fs.writeFileSync(filePath, report, 'utf-8');
                
                console.log(`[${new Date().toISOString()}] 财富数据已保存：${fileName}`);
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    success: true,
                    message: '数据已保存',
                    file: fileName
                }));
            } catch (error) {
                console.error('保存失败:', error);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    success: false,
                    error: error.message
                }));
            }
        });
        return;
    }
    
    // 获取本周数据
    if (req.method === 'GET' && req.url === '/api/this-week') {
        try {
            const today = new Date();
            const year = today.getFullYear();
            const weekNum = getWeekNumber(today);
            const fileName = `W${weekNum}-wealth-stats.md`;
            const filePath = path.join(DATA_DIR, year.toString(), fileName);
            
            if (fs.existsSync(filePath)) {
                const content = fs.readFileSync(filePath, 'utf-8');
                res.writeHead(200, { 'Content-Type': 'text/markdown; charset=utf-8' });
                res.end(content);
            } else {
                res.writeHead(404, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    success: false,
                    error: '本周数据不存在'
                }));
            }
        } catch (error) {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                success: false,
                error: error.message
            }));
        }
        return;
    }
    
    // 状态检查
    if (req.method === 'GET' && req.url === '/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'ok',
            port: PORT,
            dataDir: DATA_DIR,
            timestamp: new Date().toISOString()
        }));
        return;
    }
    
    // 404
    res.writeHead(404);
    res.end('Not Found');
});

// 计算周数
function getWeekNumber(date) {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
}

// 生成财富报告
function generateWealthReport(data) {
    const date = data.date || new Date().toISOString().split('T')[0];
    const weekNum = data.weekNum || getWeekNumber(new Date(date));
    const year = data.year || new Date().getFullYear();
    
    const totalAssets = (data.balances.bank || 0) + 
                       (data.balances.digital || 0) + 
                       (data.balances.investment || 0) + 
                       (data.balances.cash || 0);
    
    let report = `# 💰 财富堡每周复盘 - 第${weekNum}周 (${year}年)\n\n`;
    report += `**记录时间:** ${new Date().toISOString()}\n`;
    report += `**统计周期:** 第${weekNum}周\n\n`;
    
    report += `---\n\n`;
    
    report += `## 📊 本周概览\n\n`;
    report += `| 项目 | 金额 |\n`;
    report += `|------|------|\n`;
    report += `| 本周总收入 | ¥${(data.summary?.totalIncome || 0).toFixed(2)} |\n`;
    report += `| 本周总支出 | ¥${(data.summary?.totalExpense || 0).toFixed(2)} |\n`;
    report += `| 本周结余 | ¥${(data.summary?.weekBalance || 0).toFixed(2)} |\n`;
    report += `| 储蓄率 | ${data.summary?.savingRate?.toFixed(1) || 0}% |\n\n`;
    
    report += `## 💰 本周收入\n\n`;
    report += `| 收入类型 | 金额 |\n`;
    report += `|----------|------|\n`;
    report += `| 工资 | ¥${(data.income?.salary || 0).toFixed(2)} |\n`;
    report += `| 奖金/绩效 | ¥${(data.income?.bonus || 0).toFixed(2)} |\n`;
    report += `| 投资回报 | ¥${(data.income?.investment || 0).toFixed(2)} |\n`;
    report += `| 兼职/副业 | ¥${(data.income?.side || 0).toFixed(2)} |\n`;
    report += `| 其他 | ¥${(data.income?.other || 0).toFixed(2)} |\n`;
    report += `| **总收入** | **¥${(data.summary?.totalIncome || 0).toFixed(2)}** |\n\n`;
    
    report += `## 💸 本周支出\n\n`;
    report += `| 支出类型 | 金额 |\n`;
    report += `|----------|------|\n`;
    report += `| 餐饮 | ¥${(data.expense?.food || 0).toFixed(2)} |\n`;
    report += `| 交通 | ¥${(data.expense?.transport || 0).toFixed(2)} |\n`;
    report += `| 购物 | ¥${(data.expense?.shopping || 0).toFixed(2)} |\n`;
    report += `| 娱乐 | ¥${(data.expense?.entertainment || 0).toFixed(2)} |\n`;
    report += `| 学习 | ¥${(data.expense?.learning || 0).toFixed(2)} |\n`;
    report += `| 医疗 | ¥${(data.expense?.medical || 0).toFixed(2)} |\n`;
    report += `| 住房 | ¥${(data.expense?.housing || 0).toFixed(2)} |\n`;
    report += `| 其他 | ¥${(data.expense?.other || 0).toFixed(2)} |\n`;
    report += `| **总支出** | **¥${(data.summary?.totalExpense || 0).toFixed(2)}** |\n\n`;
    
    report += `## 🏦 账户余额（截至本周日）\n\n`;
    report += `| 账户类型 | 余额 |\n`;
    report += `|----------|------|\n`;
    report += `| 银行卡 | ¥${(data.balances.bank || 0).toFixed(2)} |\n`;
    report += `| 支付宝/微信 | ¥${(data.balances.digital || 0).toFixed(2)} |\n`;
    report += `| 投资账户 | ¥${(data.balances.investment || 0).toFixed(2)} |\n`;
    report += `| 现金 | ¥${(data.balances.cash || 0).toFixed(2)} |\n`;
    report += `| **总资产** | **¥${totalAssets.toFixed(2)}** |\n\n`;
    
    report += `## 🎯 储蓄目标\n\n`;
    const goal = data.savingGoal?.monthly || 0;
    const current = data.savingGoal?.current || 0;
    const percentage = goal > 0 ? ((current / goal) * 100).toFixed(1) : 0;
    report += `- 本月目标：¥${goal.toFixed(2)}\n`;
    report += `- 已完成：¥${current.toFixed(2)} (${percentage}%)\n\n`;
    
    report += `## 💭 财务反思\n\n`;
    report += `### 本周最大支出\n${data.reflection?.topExpense || '无'}\n\n`;
    report += `### 冲动消费反思\n${data.reflection?.impulseBuying || '无'}\n\n`;
    report += `### 理财心得\n${data.reflection?.financeInsight || '无'}\n\n`;
    report += `### 下周计划\n${data.reflection?.nextWeekPlan || '无'}\n\n`;
    
    report += `---\n\n`;
    report += `_数据由财富堡 HTML 表单自动记录_\n`;
    
    return report;
}

server.listen(PORT, '0.0.0.0', () => {
    console.log(`\n💰 财富堡服务器已启动`);
    console.log(`📊 端口：${PORT}`);
    console.log(`💾 数据目录：${DATA_DIR}`);
    console.log(`🌐 访问地址：http://localhost:${PORT}`);
    console.log(`\n按 Ctrl+C 停止服务\n`);
});

// 优雅退出
process.on('SIGINT', () => {
    console.log('\n服务器正在关闭...');
    server.close(() => {
        console.log('服务器已关闭');
        process.exit(0);
    });
});
