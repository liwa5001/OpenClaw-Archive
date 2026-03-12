#!/usr/bin/env node
/**
 * 健康堡问卷回复解析器
 * 解析飞书用户回复，提取运动/饮食/睡眠数据
 * 更新统计文件并生成确认消息
 */

const fs = require('fs');
const path = require('path');

const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const STATS_DIR = path.join(WORKSPACE, 'daily-output/health/daily-stats');

/**
 * 解析用户回复
 * @param {string} replyText - 用户回复的文本
 * @param {string} date - 日期 YYYY-MM-DD
 * @returns {object} - 解析后的数据结构
 */
function parseHealthReply(replyText, date) {
    const data = {
        date: date,
        exercise: { status: '待补充', type: '-', duration: '-', distance: '-', calories: '-', rating: '-' },
        food: { breakfast: '待补充', lunch: '待补充', dinner: '待补充', total: '-', type: '-' },
        sleep: { rating: '-', bedtime: '-', waketime: '-', duration: '-', deepSleep: '-', rhr: '-' },
        weight: '-',
        scores: { exercise: '-', food: '-', sleep: '-', total: '-' },
        suggestions: []
    };

    const lines = replyText.split('\n').map(l => l.trim()).filter(l => l);

    for (const line of lines) {
        // 解析运动数据 A1, 骑行，90, 3
        if (line.match(/^A[01]/i)) {
            const match = line.match(/A([01])[,\s]*(.*)/i);
            if (match) {
                if (match[1] === '0') {
                    data.exercise.status = '😴 休息日';
                    data.exercise.type = '无';
                } else {
                    data.exercise.status = '✅ 有记录';
                    const parts = match[2].split(/[,,]/).map(p => p.trim());
                    if (parts[0]) data.exercise.type = parts[0];
                    if (parts[1]) data.exercise.duration = parts[1].replace(/分钟|min/, '');
                    if (parts[2]) data.exercise.rating = parts[2].replace(/分/, '');
                    // 估算卡路里（按骑行 8 kcal/min）
                    if (data.exercise.duration !== '-') {
                        data.exercise.calories = Math.round(parseInt(data.exercise.duration) * 8);
                    }
                }
            }
        }

        // 解析饮食数据 B 早餐：...
        if (line.match(/^B/i)) {
            if (line.includes('早餐')) {
                const match = line.match(/早餐 [::]\s*(.+)/);
                if (match) data.food.breakfast = match[1];
            }
            if (line.includes('午餐')) {
                const match = line.match(/午餐 [::]\s*(.+)/);
                if (match) data.food.lunch = match[1];
            }
            if (line.includes('晚餐')) {
                const match = line.match(/晚餐 [::]\s*(.+)/);
                if (match) data.food.dinner = match[1];
            }
            // 简单模式 B1/B2/B3
            if (line.match(/B([123])/)) {
                const type = line.match(/B([123])/)[1];
                data.food.type = type === '1' ? '清淡' : type === '2' ? '正常' : '油腻';
                data.food.total = type === '1' ? '1500' : type === '2' ? '1800' : '2200';
            }
        }

        // 解析睡眠数据 C3, 23:30, 7.5 小时，52bpm
        if (line.match(/^C/i)) {
            const parts = line.split(/[,,]/).map(p => p.trim());
            for (const part of parts) {
                if (part.match(/^C[1-5]/)) {
                    data.sleep.rating = part.match(/C([1-5])/)[1];
                }
                if (part.match(/\d{1,2}:\d{2}/)) {
                    data.sleep.bedtime = part.match(/(\d{1,2}:\d{2})/)[1];
                }
                if (part.match(/\d+\.?\d*\s*(小时|h)/)) {
                    data.sleep.duration = part.match(/(\d+\.?\d*)\s*(小时|h)/)[1];
                }
                if (part.match(/\d+\s*bpm/)) {
                    data.sleep.rhr = part.match(/(\d+)\s*bpm/)[1];
                }
                if (part.match(/深睡 [::]\s*(\d+\.?\d*)/)) {
                    data.sleep.deepSleep = part.match(/深睡 [::]\s*(\d+\.?\d*)/)[1];
                }
                if (part.match(/起床 [::]\s*(\d{1,2}:\d{2})/)) {
                    data.sleep.waketime = part.match(/起床 [::]\s*(\d{1,2}:\d{2})/)[1];
                }
            }
        }

        // 解析体重 D 84.5kg
        if (line.match(/^D/i)) {
            const match = line.match(/D\s*(\d+\.?\d*)\s*kg/);
            if (match) data.weight = match[1] + ' kg';
        }
    }

    // 计算评分
    data.scores.exercise = data.exercise.status.includes('✅') ? '40' : data.exercise.status.includes('休息') ? '30' : '0';
    data.scores.food = data.food.breakfast !== '待补充' ? '30' : '15';
    data.scores.sleep = data.sleep.rating !== '-' ? (parseInt(data.sleep.rating) * 6).toString() : '15';
    
    const total = (parseInt(data.scores.exercise) || 0) + 
                  (parseInt(data.scores.food) || 0) + 
                  (parseInt(data.scores.sleep) || 0);
    data.scores.total = total.toString();

    // 生成建议
    if (data.exercise.status.includes('休息')) {
        data.suggestions.push('🏃 今天安排一次恢复性运动吧！Z2 骑行 30-45km');
    } else {
        data.suggestions.push('💪 运动状态良好，注意保持训练节奏');
    }
    if (data.sleep.rating !== '-' && parseInt(data.sleep.rating) < 3) {
        data.suggestions.push('😴 睡眠质量一般，今晚尝试提前 30 分钟入睡');
    }
    if (data.food.type === '油腻') {
        data.suggestions.push('🍽️ 饮食偏油腻，建议明日清淡一些');
    }

    return data;
}

/**
 * 更新统计文件
 * @param {object} data - 解析后的数据
 * @param {string} date - 日期 YYYY-MM-DD
 */
function updateStatsFile(data, date) {
    const statsFile = path.join(STATS_DIR, `${date}-health-stats.md`);
    
    if (!fs.existsSync(statsFile)) {
        console.log(`统计文件不存在：${statsFile}`);
        return false;
    }

    let content = fs.readFileSync(statsFile, 'utf8');

    // 更新运动数据
    if (data.exercise.status !== '待补充') {
        content = content.replace(/\| 训练状态 \| [^\|]+\|/, `| 训练状态 | ${data.exercise.status} |`);
        content = content.replace(/\| 运动类型 \| [^\|]+\|/, `| 运动类型 | ${data.exercise.type} |`);
        content = content.replace(/\| 运动时长 \| [^\|]+\|/, `| 运动时长 | ${data.exercise.duration} |`);
        content = content.replace(/\| 运动距离 \| [^\|]+\|/, `| 运动距离 | ${data.exercise.distance} |`);
        content = content.replace(/\| 估算消耗 \| [^\|]+\|/, `| 估算消耗 | ${data.exercise.calories} |`);
    }

    // 更新饮食数据
    content = content.replace(/\| 早餐 \| 待补充 \| 待补充 \|/g, `| 早餐 | ${data.food.breakfast} | 待计算 |`);
    content = content.replace(/\| 午餐 \| 待补充 \| 待补充 \|/g, `| 午餐 | ${data.food.lunch} | 待计算 |`);
    content = content.replace(/\| 晚餐 \| 待补充 \| 待补充 \|/g, `| 晚餐 | ${data.food.dinner} | 待计算 |`);
    if (data.food.total !== '-') {
        content = content.replace(/\| \*\*总计\*\* \| - \| - \| \*\*待补充 kcal\*\*\|/, `| **总计** | - | - | **${data.food.total} kcal**|`);
    }

    // 更新睡眠数据
    if (data.sleep.bedtime !== '-') {
        content = content.replace(/\| 入睡时间 \| 待补充 \|/g, `| 入睡时间 | ${data.sleep.bedtime} |`);
    }
    if (data.sleep.waketime !== '-') {
        content = content.replace(/\| 起床时间 \| 待补充 \|/g, `| 起床时间 | ${data.sleep.waketime} |`);
    }
    if (data.sleep.duration !== '-') {
        content = content.replace(/\| 睡眠时长 \| 待补充 \|/g, `| 睡眠时长 | ${data.sleep.duration} |`);
    }
    if (data.sleep.deepSleep !== '-') {
        content = content.replace(/\| 深睡时长 \| 待补充 \|/g, `| 深睡时长 | ${data.sleep.deepSleep} |`);
    }
    if (data.sleep.rhr !== '-') {
        content = content.replace(/\| 静息心率 \| 待补充 \|/g, `| 静息心率 | ${data.sleep.rhr} |`);
    }
    if (data.sleep.rating !== '-') {
        content = content.replace(/\| 睡眠评分 \| 待补充 \|/g, `| 睡眠评分 | ${data.sleep.rating}/5 |`);
    }

    // 更新评分
    content = content.replace(/\| 运动达标 \| - \| 40 \| -% \| [^\|]+\|/, `| 运动达标 | ${data.scores.exercise}/40 | 40 | ${Math.round(parseInt(data.scores.exercise)*100/40)}% | ${data.exercise.status} |`);
    content = content.replace(/\| 饮食健康 \| - \| 30 \| -% \| 待补充 \|/, `| 饮食健康 | ${data.scores.food}/30 | 30 | ${Math.round(parseInt(data.scores.food)*100/30)}% | ${data.food.type || '待补充'} |`);
    content = content.replace(/\| 睡眠质量 \| - \| 30 \| -% \| 待补充 \|/, `| 睡眠质量 | ${data.scores.sleep}/30 | 30 | ${Math.round(parseInt(data.scores.sleep)*100/30)}% | 基于问卷 |`);
    content = content.replace(/\| \*\*综合评分\*\* \| \*\*-\*\* \| \*\*100\*\* \| \*\*-%\*\* \| \*\*待计算\*\* \|/, `| **综合评分** | **${data.scores.total}/100** | **100** | **${parseInt(data.scores.total)}%** | **已计算** |`);

    // 更新建议
    if (data.suggestions.length > 0) {
        const suggestionsText = data.suggestions.join('\n\n');
        content = content.replace(/⏳ 等待数据录入后自动生成\.\.\./, suggestionsText);
    }

    // 更新原始数据
    content = content.replace(/```\n待补充 - 请回复飞书问卷填写数据\n```/, `\`\`\`\n${data.rawReply || '已解析'}\n\`\`\``);

    // 更新状态
    content = content.replace(/\*\*状态：\*\* 📝 等待用户回复问卷/, `**状态：** ✅ 已接收用户回复`);

    fs.writeFileSync(statsFile, content);
    console.log(`✅ 统计文件已更新：${statsFile}`);
    return true;
}

/**
 * 生成确认消息
 * @param {object} data - 解析后的数据
 * @returns {string} - 确认消息文本
 */
function generateConfirmation(data) {
    return `✅ 收到！今日数据已记录：

【${data.date} 健康数据】
🏃 运动：${data.exercise.type} ${data.exercise.duration !== '-' ? data.exercise.duration + '分钟' : ''} ${data.exercise.rating !== '-' ? '(强度' + data.exercise.rating + '/5)' : ''}
🍽️ 饮食：${data.food.type || '待补充'} ${data.food.total !== '-' ? '(~' + data.food.total + 'kcal)' : ''}
😴 睡眠：${data.sleep.rating !== '-' ? data.sleep.rating + '/5 分' : '待补充'} ${data.sleep.duration !== '-' ? '(' + data.sleep.duration + '小时)' : ''} ${data.sleep.rhr !== '-' ? '(RHR ' + data.sleep.rhr + 'bpm)' : ''}
${data.weight !== '-' ? '⚖️ 体重：' + data.weight : ''}

【今日评分】
运动：${data.scores.exercise}/40 ${parseInt(data.scores.exercise) >= 30 ? '✅' : '⚠️'}
饮食：${data.scores.food}/30 ${parseInt(data.scores.food) >= 20 ? '✅' : '⚠️'}
睡眠：${data.scores.sleep}/30 ${parseInt(data.scores.sleep) >= 20 ? '✅' : '⚠️'}
**综合：${data.scores.total}/100**

【明日建议】
${data.suggestions.join('\n')}

继续加油！💪

🏰 城堡健康堡`;
}

// 命令行使用
if (process.argv.length > 2) {
    const action = process.argv[2];
    
    if (action === 'parse' && process.argv[3] && process.argv[4]) {
        const replyText = process.argv.slice(3).join(' ');
        const date = process.argv[4] || new Date().toISOString().split('T')[0];
        
        console.log(`解析回复：${replyText}`);
        const data = parseHealthReply(replyText, date);
        console.log('解析结果：', JSON.stringify(data, null, 2));
        
        updateStatsFile(data, date);
        
        const confirmation = generateConfirmation(data);
        console.log('\n确认消息：');
        console.log(confirmation);
    } else if (action === 'test') {
        // 测试用例
        const testReply = `A1, 骑行，90, 3
早餐：8:00 2 个包子 +1 杯豆浆
午餐：12:30 1 碗米饭 + 宫保鸡丁 + 炒青菜
晚餐：18:30 半碗米饭 + 清蒸鱼 + 凉拌黄瓜
C3, 23:00, 6:30, 深睡 2h, 浅睡 4.5h, RHR 52bpm`;
        
        const data = parseHealthReply(testReply, '2026-03-10');
        console.log('测试解析结果：', JSON.stringify(data, null, 2));
    } else {
        console.log('用法：');
        console.log('  node parse-health-reply.js parse "回复内容" YYYY-MM-DD');
        console.log('  node parse-health-reply.js test');
    }
}

module.exports = { parseHealthReply, updateStatsFile, generateConfirmation };
