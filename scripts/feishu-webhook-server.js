#!/usr/bin/env node
/**
 * 飞书 Webhook 消息同步服务器
 * 接收飞书事件推送，转发消息到 Webchat
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.FEISHU_WEBHOOK_PORT || 8888;
const WORKSPACE = '/Users/liwang/.openclaw/workspace';
const CONFIG_PATH = path.join(WORKSPACE, 'config/feishu-webhook-config.json');
const LOG_PATH = path.join(WORKSPACE, 'logs/feishu-webhook.log');

// 加载配置
let config = { verifyToken: '', encryptKey: '' };
try {
    config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
} catch (e) {
    console.log('配置文件不存在，使用默认配置');
}

function log(message) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(LOG_PATH, logLine);
    console.log(logLine.trim());
}

// 验证飞书签名
function verifySignature(timestamp, nonce, signature) {
    if (!config.verifyToken) {
        log('警告：verifyToken 未配置');
        return true; // 开发模式跳过验证
    }
    
    const arr = [config.verifyToken, timestamp, nonce];
    arr.sort();
    const str = arr.join('');
    const hash = crypto.createHash('sha1').update(str).digest('hex');
    return hash === signature;
}

// 处理飞书消息事件
function handleMessageEvent(event) {
    log(`收到消息事件：${JSON.stringify(event)}`);
    
    const { header, event: eventData } = event;
    
    // 只处理接收到的消息
    if (header.event_type !== 'im.message.receive_v1') {
        log(`跳过事件类型：${header.event_type}`);
        return;
    }
    
    const { message } = eventData;
    
    // 过滤自己发送的消息（避免循环）
    if (message.sender_id.type === 'bot_id') {
        log('跳过机器人自己发送的消息');
        return;
    }
    
    // 提取消息内容
    const content = JSON.parse(message.content || '{}');
    const text = content.text || content.content || '[非文本消息]';
    const sender = message.sender_id.user_id || '未知用户';
    
    log(`消息来自 ${sender}: ${text}`);
    
    // 转发到 webchat - 已禁用 (2026-03-08)
    // try {
    //     const cmd = `/opt/homebrew/bin/openclaw message send --channel webchat --message "📨 飞书消息 (来自 ${sender}):\n${text}"`;
    //     execSync(cmd, { stdio: 'pipe' });
    //     log('消息已转发到 webchat');
    // } catch (e) {
    //     log(`转发失败：${e.message}`);
    // }
    log('[已禁用] 跳过转发消息到 webchat');
}

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    
    // GET 请求 - 飞书验证
    if (req.method === 'GET' && url.pathname === config.webhook?.path || url.pathname === '/feishu/webhook') {
        const params = url.searchParams;
        const timestamp = params.get('timestamp');
        const nonce = params.get('nonce');
        const signature = params.get('signature');
        const echoToken = params.get('echo_token');
        
        log(`验证请求：timestamp=${timestamp}, signature=${signature}`);
        
        if (verifySignature(timestamp, nonce, signature)) {
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end(echoToken);
            log('验证成功');
        } else {
            res.writeHead(403);
            res.end('Invalid signature');
            log('验证失败');
        }
        return;
    }
    
    // POST 请求 - 事件推送
    if (req.method === 'POST' && (url.pathname === config.webhook?.path || url.pathname === '/feishu/webhook')) {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const event = JSON.parse(body);
                log(`收到事件：${event.header?.event_type}`);
                handleMessageEvent(event);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true }));
            } catch (e) {
                log(`解析失败：${e.message}`);
                res.writeHead(400);
                res.end('Invalid JSON');
            }
        });
        return;
    }
    
    // 其他请求
    res.writeHead(404);
    res.end('Not Found');
});

server.listen(PORT, () => {
    log(`飞书 Webhook 服务器启动在端口 ${PORT}`);
    log(`Webhook URL: http://your-public-ip:${PORT}/feishu/webhook`);
});
