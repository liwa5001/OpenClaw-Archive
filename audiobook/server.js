const express = require('express');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const PORT = 8895;

app.use(express.json());
app.use(express.static(__dirname));

// 数据存储路径
const PROGRESS_FILE = path.join(__dirname, 'progress', 'user-progress.json');
const AUDIO_DIR = path.join(__dirname, 'audio');

// 确保目录存在
if (!fs.existsSync(path.join(__dirname, 'progress'))) {
    fs.mkdirSync(path.join(__dirname, 'progress'), { recursive: true });
}
if (!fs.existsSync(AUDIO_DIR)) {
    fs.mkdirSync(AUDIO_DIR, { recursive: true });
}

// 加载进度
function loadProgress() {
    try {
        if (fs.existsSync(PROGRESS_FILE)) {
            return JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
        }
    } catch (e) {
        console.error('加载进度失败:', e);
    }
    return {
        userId: 'default',
        currentDay: 1,
        currentTime: {},
        completedDays: [],
        totalTime: 0,
        lastListen: null,
        history: []
    };
}

// 保存进度
function saveProgress(data) {
    try {
        fs.writeFileSync(PROGRESS_FILE, JSON.stringify(data, null, 2));
        return true;
    } catch (e) {
        console.error('保存进度失败:', e);
        return false;
    }
}

// API: 获取进度
app.get('/api/progress', (req, res) => {
    const progress = loadProgress();
    res.json(progress);
});

// API: 保存进度
app.post('/api/progress', (req, res) => {
    const { day, time, duration } = req.body;
    const progress = loadProgress();
    
    // 更新进度
    progress.currentTime[day] = time;
    progress.currentDay = day;
    progress.lastListen = new Date().toISOString();
    
    // 记录历史
    progress.history.push({
        day,
        time,
        duration,
        timestamp: new Date().toISOString()
    });
    
    // 检查是否完成
    if (duration && time >= duration * 0.9) {
        if (!progress.completedDays.includes(day)) {
            progress.completedDays.push(day);
            progress.totalTime += Math.round(duration);
        }
    }
    
    saveProgress(progress);
    
    // 同步到成长堡数据
    syncToGrowthData(progress);
    
    res.json({ success: true, progress });
});

// 同步到成长堡数据
function syncToGrowthData(progress) {
    const growthDir = path.join(__dirname, '..', 'daily-output', 'growth', 'audiobook-stats');
    if (!fs.existsSync(growthDir)) {
        fs.mkdirSync(growthDir, { recursive: true });
    }
    
    const today = new Date().toISOString().split('T')[0];
    const statsFile = path.join(growthDir, `${today}-audiobook-stats.md`);
    
    const content = `# 📚 有声读本收听记录

**日期：** ${today}
**最后更新：** ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}

## 收听进度

| 项目 | 数值 |
|------|------|
| 当前天数 | 第 ${progress.currentDay} 天 |
| 已完成 | ${progress.completedDays.length}/13 天 |
| 已听时长 | ${Math.round(progress.totalTime / 60)} 分钟 |
| 完成率 | ${Math.round(progress.completedDays.length / 13 * 100)}% |

## 收听历史

${progress.history.slice(-10).map(h => `- ${h.timestamp}: 第${h.day}天，${Math.round(h.time)}秒 / ${Math.round(h.duration)}秒`).join('\n')}

## 预计完成

${progress.lastListen ? `按当前进度，预计 ${new Date(new Date(progress.lastListen).getTime() + (13 - progress.completedDays.length) * 24 * 60 * 60 * 1000).toLocaleDateString('zh-CN')} 完成全书` : '开始收听后显示预计完成日期'}
`;
    
    fs.writeFileSync(statsFile, content);
}

// 生成 TTS 音频（使用 macOS 系统 TTS）
app.post('/api/generate', async (req, res) => {
    const { day, text } = req.body;
    
    if (!day || !text) {
        return res.status(400).json({ error: '缺少参数' });
    }
    
    const aiFile = path.join(AUDIO_DIR, `day${day.toString().padStart(2, '0')}.aiff`);
    const mp3File = path.join(AUDIO_DIR, `day${day.toString().padStart(2, '0')}.mp3`);
    
    // 使用 macOS 系统 TTS（女生声音 Mei-Jia）
    const ttsCommand = `say -v Mei-Jia -o "${aiFile}" "${text.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`;
    
    exec(ttsCommand, (error, stdout, stderr) => {
        if (error) {
            console.error('TTS 生成失败:', error);
            return res.status(500).json({ error: '音频生成失败', details: error.message });
        }
        
        // 转换为 MP3（如果 ffmpeg 可用）
        const convertCommand = `ffmpeg -y -i "${aiFile}" -codec:a libmp3lame -qscale:a 2 "${mp3File}" 2>/dev/null`;
        
        exec(convertCommand, (convError) => {
            if (convError) {
                // ffmpeg 不可用，使用 AIFF 格式
                console.log('ffmpeg 不可用，使用 AIFF 格式');
                res.json({ success: true, file: `/audio/day${day.toString().padStart(2, '0')}.aiff`, format: 'aiff' });
            } else {
                res.json({ success: true, file: `/audio/day${day.toString().padStart(2, '0')}.mp3`, format: 'mp3' });
            }
        });
    });
});

// 健康检查
app.get('/status', (req, res) => {
    res.json({
        status: 'ok',
        port: PORT,
        audioFiles: fs.existsSync(AUDIO_DIR) ? fs.readdirSync(AUDIO_DIR).length : 0,
        hasProgress: fs.existsSync(PROGRESS_FILE)
    });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
    console.log(`📚 有声读本服务器已启动`);
    console.log(`🌐 本地访问：http://localhost:${PORT}`);
    console.log(`📁 音频目录：${AUDIO_DIR}`);
    console.log(`📊 进度文件：${PROGRESS_FILE}`);
});
