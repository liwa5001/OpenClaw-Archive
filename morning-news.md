# 📰 晨报任务配置

## 任务说明

**时间：** 每天早上 7:00  
**收件人：** liwa5001@hotmail.com (iMessage)  
**状态：** ✅ 已激活

## 执行方式

每天早上 7 点，AI 自动执行以下步骤：

### 1. 抓取新闻

使用 `web_fetch` 从以下新闻源抓取最新内容：

```
🌍 国际新闻
- https://www.thepaper.cn/ (澎湃新闻)
- https://www.zaobao.com/ (联合早报)
- https://www.huxiu.com/ (虎嗅)
- https://www.tmtpost.com/new (钛媒体)

🇨🇳 国内新闻
- https://www.thepaper.cn/ (澎湃新闻)
- https://www.xinhuanet.com/ (新华网)
- https://www.tmtpost.com/new (钛媒体)
- https://www.people.com.cn/ (人民网)

🤖 AI 新闻
- https://www.tmtpost.com/new (钛媒体)
- https://www.huxiu.com/ (虎嗅)
- https://www.ithome.com/ (IT 之家)

🚗 汽车新闻
- https://www.xinhuanet.com/auto/ (新华网汽车)
- https://www.autohome.com.cn/ (汽车之家)
- https://www.tmtpost.com/new (钛媒体)
```

### 2. 整理新闻

- 每类提取 5 条最新新闻
- 提取标题和完整链接
- 确保链接可访问

### 3. 生成晨报格式

```
📰 晨报 - YYYY 年 M 月 D 日

🌍 国际新闻
1. 新闻标题
https://完整链接

2. 新闻标题
https://完整链接

... (每类 5 条)

🇨🇳 国内新闻
...

🤖 AI 新闻
...

🚗 汽车新闻
...

---
🏰 城堡晨报 | 自动发送
```

### 4. 发送 iMessage

```bash
imsg send --to "liwa5001@hotmail.com" --text "[晨报内容]"
```

### 5. 记录日志

写入到 `memory/YYYY-MM-DD.md`

## Cron 设置

```bash
# 查看当前 cron
crontab -l

# 已设置：每天 7:00 执行
0 7 * * * cd /Users/liwang/.openclaw/workspace && ./scripts/morning-news.sh >> logs/morning-news.log 2>&1
```

## 相关文件

| 文件 | 说明 |
|------|------|
| `scripts/morning-news.sh` | 主执行脚本 |
| `HEARTBEAT.md` | 任务配置说明 |
| `memory/2026-03-03.md` | 新闻源配置 |
| `logs/morning-news.log` | 执行日志 |

## 测试记录

- **2026-03-03 12:04** - 首次测试 ✅ 成功
- **2026-03-03 12:41** - 方案 A 确认（AI 动态抓取）
- **2026-03-04 07:00** - 首次正式运行（计划）

## 新闻源状态

### ✅ 稳定源（14 个）
澎湃新闻、联合早报、虎嗅、钛媒体、新华网、人民网、IT 之家、新华网汽车、汽车之家、中国新闻网、财经网、China Daily、钛媒体汽车、虎嗅车与出行

### ❌ 失败源（8 个）
FT 中文网、BBC 中文、腾讯新闻、新浪新闻、网易新闻、36Kr、极客公园、cnBeta

---

**最后更新：** 2026-03-03 12:41  
**下次执行：** 2026-03-04 07:00
