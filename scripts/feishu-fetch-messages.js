#!/usr/bin/env node
/**
 * 飞书消息获取脚本
 * 获取最新消息并输出 JSON 格式
 */

const https = require('https');
const fs = require('fs');

const [,, CHAT_ID, TOKEN, STATE_FILE] = process.argv;

if (!CHAT_ID || !TOKEN) {
    console.error('Usage: feishu-fetch-messages.js <chat_id> <token> [state_file]');
    process.exit(1);
}

// 获取已处理的消息 ID
let processedMessages = [];
if (STATE_FILE && fs.existsSync(STATE_FILE)) {
    try {
        const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
        processedMessages = state.processed_messages || [];
    } catch (e) {
        // ignore
    }
}

const req = https.request({
    hostname: 'open.feishu.cn',
    port: 443,
    path: `/open-apis/im/v1/messages?container_id=${CHAT_ID}&container_id_type=chat&page_size=20`,
    method: 'GET',
    headers: { 'Authorization': 'Bearer ' + TOKEN }
}, (res) => {
    let body = '';
    res.on('data', (chunk) => { body += chunk; });
    res.on('end', () => {
        const result = JSON.parse(body);
        if (result.code !== 0) {
            console.error('API Error:', result.msg);
            process.exit(1);
        }
        
        const newMessages = [];
        if (result.data && result.data.items) {
            for (const msg of result.data.items) {
                // 过滤机器人自己发送的消息
                if (msg.sender && msg.sender.sender_type === 'app') continue;
                
                // 过滤已处理的消息
                if (processedMessages.includes(msg.message_id)) continue;
                
                // 解析消息内容
                let text = '';
                try {
                    const content = JSON.parse(msg.content || '{}');
                    if (content.text) {
                        text = content.text;
                    } else if (content.content) {
                        // post 类型消息
                        const blocks = JSON.parse(content.content);
                        text = blocks.map(block => 
                            Array.isArray(block) ? block.map(item => item.text || '').join('') : ''
                        ).join('\n');
                    } else {
                        text = `[${msg.msg_type || '未知'}类型消息]`;
                    }
                } catch (e) {
                    text = `[解析失败：${e.message}]`;
                }
                
                newMessages.push({
                    sender: msg.sender ? (msg.sender.id || '未知') : '未知',
                    text: text,
                    time: msg.create_time,
                    message_id: msg.message_id
                });
            }
        }
        
        // 输出新消息
        for (const msg of newMessages) {
            console.log('NEW_MESSAGE:' + JSON.stringify(msg));
        }
        
        // 更新状态
        if (STATE_FILE && newMessages.length > 0) {
            const newIds = newMessages.map(m => m.message_id);
            const updated = [...processedMessages, ...newIds].slice(-100);
            fs.writeFileSync(STATE_FILE, JSON.stringify({ processed_messages: updated }));
        }
        
        console.log(`DONE:${newMessages.length}`);
    });
});

req.on('error', (e) => {
    console.error('Request error:', e.message);
    process.exit(1);
});

req.end();
