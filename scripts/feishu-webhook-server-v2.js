#!/usr/bin/env node
/**
 * 飞书 Webhook 消息同步服务器 v2.0
 * 接收飞书事件推送，转发消息到 Webchat
 * 支持公网穿透，跨网络访问
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.FEISHU_WEBHOOK_PORT || 8899;
const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const CONFIG_PATH = path.join(WORKSPACE, 'config/feishu-webhook-config.json');
const LOG_PATH = path.join(WORKSPACE, 'logs/feishu-webhook.log');
const STATE_PATH = path.join(WORKSPACE, 'memory/feishu-mirror-state.json');

// 加载配置
let config = { 
    verifyToken: '', 
    encryptKey: '',
    feishuUserId: 'ou_7781abd1e83eae23ccf01fe627f0747f'
};
try {
    config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
} catch (e) {
    console.log('配置文件不存在，使用默认配置');
}

// 消息去重集合（内存中，重启后清空）
const processedMessages = new Set();
const MESSAGE_CACHE_EXPIRY = 3600000; // 1 小时过期

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(LOG_PATH, logLine);
    console.log(logLine.trim());
}

// 保存状态到文件
function saveState() {
    try {
        const state = {
            lastSync: Date.now(),
            processedCount: processedMessages.size
        };
        fs.writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
    } catch (e) {
        log(`保存状态失败：${e.message}`);
    }
}

// 验证飞书签名
function verifySignature(timestamp, nonce, signature) {
    if (!config.verifyToken) {
        log('警告：verifyToken 未配置，跳过验证');
        return true;
    }
    
    const arr = [config.verifyToken, timestamp, nonce];
    arr.sort();
    const str = arr.join('');
    const hash = crypto.createHash('sha1').update(str).digest('hex');
    return hash === signature;
}

// 生成消息唯一 ID
function generateMessageId(message) {
    return `${message.message_id}_${message.update_time}`;
}

// 检查消息是否已处理
function isDuplicate(messageId) {
    if (processedMessages.has(messageId)) {
        return true;
    }
    // 添加到处理集合
    processedMessages.add(messageId);
    
    // 定期清理过期消息（每 100 条清理一次）
    if (processedMessages.size % 100 === 0) {
        setTimeout(() => {
            const now = Date.now();
            for (const id of processedMessages) {
                const msgTime = parseInt(id.split('_').pop());
                if (now - msgTime > MESSAGE_CACHE_EXPIRY) {
                    processedMessages.delete(id);
                }
            }
        }, 1000);
    }
    
    return false;
}

// 转发飞书消息到 Webchat
function forwardToWebchat(sender, text, messageId) {
    // 去重检查
    if (isDuplicate(messageId)) {
        log(`[去重] 跳过已处理的消息：${messageId}`);
        return;
    }
    
    log(`转发消息到 Webchat: ${sender} - ${text.substring(0, 50)}...`);
    
    try {
        // 使用 openclaw message send 转发到 webchat
        // 注意：这里需要找到当前活跃的 webchat session
        const cmd = `/opt/homebrew/bin/openclaw sessions list --limit 1 --json 2>/dev/null`;
        const sessions = JSON.parse(execSync(cmd, { encoding: 'utf8' }));
        
        if (sessions && sessions.length > 0) {
            const currentSession = sessions[0];
            log(`找到当前 session: ${currentSession.id}`);
            
            // 转发消息
            const forwardCmd = `/opt/homebrew/bin/openclaw sessions send --sessionKey "${currentSession.id}" --message "📨 飞书消息:\n${text}" 2>&1`;
            execSync(forwardCmd, { encoding: 'utf8' });
            log('✅ 消息已转发到 Webchat');
        } else {
            log('⚠️ 未找到活跃的 webchat session');
        }
    } catch (e) {
        log(`❌ 转发失败：${e.message}`);
    }
    
    saveState();
}

// 处理飞书消息事件
function handleMessageEvent(event) {
    log(`收到消息事件：${JSON.stringify(event.header)}`);
    
    const { header, event: eventData } = event;
    
    // 只处理接收到的消息
    if (header.event_type !== 'im.message.receive_v1') {
        log(`跳过事件类型：${header.event_type}`);
        return;
    }
    
    const { message } = eventData;
    
    // 过滤自己发送的消息（避免循环）
    if (message.sender_id?.type === 'bot_id') {
        log('跳过机器人自己发送的消息');
        return;
    }
    
    // 提取消息内容
    const content = JSON.parse(message.content || '{}');
    const text = content.text || content.content || '[非文本消息]';
    const sender = message.sender_id?.user_id || '未知用户';
    const messageId = message.message_id || `msg_${Date.now()}`;
    
    log(`📨 消息来自 ${sender}: ${text.substring(0, 50)}...`);
    
    // 转发到 webchat
    forwardToWebchat(sender, text, messageId);
}

// HTTP 服务器
const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    
    // CORS 头
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    // OPTIONS 预检请求
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // GET 请求 - 飞书验证
    if (req.method === 'GET' && (url.pathname === '/feishu/webhook' || url.pathname === '/')) {
        const params = url.searchParams;
        const timestamp = params.get('timestamp');
        const nonce = params.get('nonce');
        const signature = params.get('signature');
        const echoToken = params.get('echo_token');
        
        log(`🔐 验证请求：timestamp=${timestamp}`);
        
        if (verifySignature(timestamp, nonce, signature)) {
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end(echoToken);
            log('✅ 验证成功');
        } else {
            res.writeHead(403);
            res.end('Invalid signature');
            log('❌ 验证失败');
        }
        return;
    }
    
    // POST 请求 - 事件推送
    if (req.method === 'POST' && (url.pathname === '/feishu/webhook' || url.pathname === '/')) {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            log(`📝 POST 原始请求体：${body.substring(0, 200)}`);
            try {
                const data = JSON.parse(body);
                
                // 处理 url_verification 事件（飞书保存时的验证）- 扁平结构
                if (data.type === 'url_verification' || data.header?.event_type === 'url_verification') {
                    log('🔐 URL 验证请求');
                    // 飞书使用扁平结构：{challenge, token, type}
                    const challenge = data.challenge || data.event?.challenge || '';
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ challenge }));
                    log('✅ URL 验证成功，返回 challenge: ' + challenge);
                    return;
                }
                
                // 标准事件结构：{header: {event_type}, event: {...}}
                const event = data;
                log(`📥 收到事件：${event.header?.event_type}`);
                handleMessageEvent(event);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true }));
            } catch (e) {
                log(`❌ 解析失败：${e.message}`);
                log(`❌ 原始请求体：${body}`);
                res.writeHead(400);
                res.end(JSON.stringify({ error: e.message }));
            }
        });
        return;
    }
    
    // 状态检查端点
    if (req.method === 'GET' && url.pathname === '/status') {
        const status = {
            status: 'running',
            port: PORT,
            processedMessages: processedMessages.size,
            lastSync: new Date().toISOString()
        };
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(status));
        return;
    }
    
    // 其他请求
    res.writeHead(404);
    res.end('Not Found');
});

server.listen(PORT, () => {
    log(`🚀 飞书 Webhook 服务器 v2.0 启动在端口 ${PORT}`);
    log(`🌐 Webhook URL: http://your-public-ip:${PORT}/feishu/webhook`);
    log(`📊 状态检查：http://localhost:${PORT}/status`);
});

// 优雅关闭
process.on('SIGINT', () => {
    log('服务器正在关闭...');
    saveState();
    server.close(() => {
        log('服务器已关闭');
        process.exit(0);
    });
});
