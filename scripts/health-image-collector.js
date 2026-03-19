#!/usr/bin/env node
/**
 * 飞书健康数据图片收集器
 * 监听飞书消息中的图片，自动触发识别
 */

const http = require('http');
const crypto = require('crypto');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const PORT = 8900;
const LOG_FILE = '/Users/liwang/.openclaw/workspace/logs/health-image-collector.log';

function log(message) {
    const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
    const line = `[${timestamp}] ${message}\n`;
    console.log(line);
    fs.appendFileSync(LOG_FILE, line);
}

// 解析飞书事件
function parseFeishuEvent(body) {
    try {
        const event = JSON.parse(body);
        return event;
    } catch (e) {
        log(`❌ 解析失败：${e.message}`);
        return null;
    }
}

// 判断是否是图片消息
function isImageMessage(event) {
    // 飞书图片消息类型
    if (event.header && event.header.event_type === 'im.message.receive_v1') {
        const msg = event.event?.message;
        if (msg) {
            // 检查消息内容是否包含图片
            const content = JSON.parse(msg.content || '{}');
            if (content.image_key || msg.message_type === 'image') {
                return true;
            }
            // 检查是否包含健康数据标签
            const text = content.text || '';
            if (text.includes('#睡眠') || text.includes('#早餐') || 
                text.includes('#午餐') || text.includes('#晚餐') || 
                text.includes('#体重')) {
                return true;
            }
        }
    }
    return false;
}

// 提取图片信息
function extractImageInfo(event) {
    try {
        const msg = event.event?.message;
        const content = JSON.parse(msg?.content || '{}');
        
        // 获取图片 key
        const imageKey = content.image_key;
        
        // 获取消息文本（用于判断类型）
        const text = content.text || msg.content || '';
        
        // 判断图片类型
        let imageType = 'unknown';
        if (text.includes('#睡眠') || text.includes('睡眠')) imageType = 'sleep';
        else if (text.includes('#早餐') || text.includes('早餐')) imageType = 'breakfast';
        else if (text.includes('#午餐') || text.includes('午餐')) imageType = 'lunch';
        else if (text.includes('#晚餐') || text.includes('晚餐')) imageType = 'dinner';
        else if (text.includes('#体重') || text.includes('体重')) imageType = 'weight';
        
        // 发送者 ID
        const senderId = event.event?.sender?.user_id;
        
        log(`📷 图片消息：key=${imageKey}, type=${imageType}, sender=${senderId}`);
        
        return { imageKey, imageType, senderId };
    } catch (e) {
        log(`❌ 提取信息失败：${e.message}`);
        return null;
    }
}

// 下载飞书图片
function downloadFeishuImage(imageKey) {
    return new Promise((resolve, reject) => {
        // 使用飞书 API 下载图片
        const script = `
            curl -s -X GET \\
                "https://open.feishu.cn/open-apis/im/v1/images/${imageKey}" \\
                -H "Authorization: Bearer $(cat /Users/liwang/.openclaw/workspace/feishu-app-token.txt 2>/dev/null || echo '')" \\
                -o /tmp/health-image-${Date.now()}.jpg
        `;
        
        exec(script, (error, stdout, stderr) => {
            if (error) {
                reject(error);
            } else {
                resolve(`/tmp/health-image-${Date.now()}.jpg`);
            }
        });
    });
}

// 调用识别脚本
function recognizeImage(imagePath, imageType) {
    return new Promise((resolve, reject) => {
        const script = `/Users/liwang/.openclaw/workspace/scripts/health-image-recognition.sh "${imagePath}" "${imageType}"`;
        
        exec(script, { timeout: 120000 }, (error, stdout, stderr) => {
            if (error) {
                log(`❌ 识别失败：${error.message}`);
                reject(error);
            } else {
                log(`✅ 识别完成：${stdout}`);
                resolve(stdout);
            }
        });
    });
}

// HTTP 服务器
const server = http.createServer(async (req, res) => {
    if (req.method === 'POST' && req.url === '/health-image/webhook') {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', async () => {
            log(`📨 收到请求：${req.url}`);
            
            const event = parseFeishuEvent(body);
            if (!event) {
                res.writeHead(400);
                res.end('Invalid event');
                return;
            }
            
            // 验证挑战（飞书 webhook 验证）
            if (event.type === 'url_verification') {
                log('🔐 URL 验证请求');
                res.writeHead(200);
                res.end(event.challenge);
                return;
            }
            
            // 处理图片消息
            if (isImageMessage(event)) {
                log('🖼️ 检测到图片消息');
                
                const imageInfo = extractImageInfo(event);
                if (imageInfo && imageInfo.imageKey) {
                    try {
                        // 下载图片
                        log('⬇️ 下载图片...');
                        const imagePath = await downloadFeishuImage(imageInfo.imageKey);
                        
                        // 识别图片
                        log('🔍 识别图片...');
                        await recognizeImage(imagePath, imageInfo.imageType);
                        
                        res.writeHead(200);
                        res.end('OK');
                    } catch (e) {
                        log(`❌ 处理失败：${e.message}`);
                        res.writeHead(500);
                        res.end(e.message);
                    }
                } else {
                    res.writeHead(400);
                    res.end('No image found');
                }
            } else {
                log('ℹ️ 非图片消息，忽略');
                res.writeHead(200);
                res.end('Ignored');
            }
        });
    } else if (req.method === 'GET' && req.url === '/health-image/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'running',
            port: PORT,
            uptime: process.uptime()
        }));
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(PORT, () => {
    log(`🚀 健康图片收集器已启动，端口：${PORT}`);
    log(`📡 Webhook URL: http://localhost:${PORT}/health-image/webhook`);
});

// 优雅退出
process.on('SIGTERM', () => {
    log('👋 收到 SIGTERM，退出...');
    server.close(() => {
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    log('👋 收到 SIGINT，退出...');
    server.close(() => {
        process.exit(0);
    });
});
