# 📸 健康堡图片识别配置指南

## ✅ 已完成配置

| 组件 | 状态 | 端口/路径 |
|------|------|----------|
| 图片识别脚本 | ✅ 就绪 | `scripts/health-image-recognition.sh` |
| Webhook 服务器 | ✅ 运行中 | 8900 |
| 启动脚本 | ✅ 就绪 | `scripts/start-health-image-collector.sh` |

---

## 📱 使用方法

### 方式 1：飞书私聊（推荐）

**步骤：**
1. 在飞书给 **OpenClaw bot** 发送图片
2. 添加标签帮助识别（可选）：
   - `#睡眠` - 华为健康睡眠截图
   - `#早餐` - 早餐照片
   - `#午餐` - 午餐照片
   - `#晚餐` - 晚餐照片
   - `#体重` - 体重秤照片

**示例消息：**
```
#睡眠
[发送华为健康 App 截图]
```

**自动识别内容：**
- 睡眠截图 → 入睡/起床时间、深睡/浅睡/REM、静息心率
- 三餐照片 → 食物名称、估算份量
- 体重照片 → 体重、体脂率、BMI

**识别后：**
- ✅ 自动保存数据到对应文件
- ✅ 飞书回复确认消息

---

## 🔧 飞书后台配置（如需 webhook）

**如果飞书 bot 无法自动接收图片，需要配置：**

1. 登录 [飞书开发者后台](https://open.feishu.cn/app)
2. 选择 **OpenClaw** 应用
3. 进入 **事件与回调** → **回调配置**
4. 配置订阅地址：
   ```
   http://你的公网 IP:8900/health-image/webhook
   ```
   （如需公网访问，使用 Cloudflare Tunnel）
5. 验证令牌：留空
6. 订阅事件：`im.message.receive_v1`
7. 保存

---

## 🖥️ 服务器管理

```bash
# 启动图片收集器
./scripts/start-health-image-collector.sh

# 查看状态
curl http://localhost:8900/health-image/status

# 查看日志
tail -f logs/health-image-collector.log

# 查看识别结果
ls -la health-data/recognized/

# 停止服务
pkill -f health-image-collector.js
```

---

## 📁 数据保存位置

| 类型 | 保存路径 |
|------|---------|
| 睡眠数据 | `daily-output/health/sleep-data/YYYY-MM-DD-sleep.md` |
| 早餐 | `daily-output/health/meal-data/YYYY-MM-DD-breakfast.md` |
| 午餐 | `daily-output/health/meal-data/YYYY-MM-DD-lunch.md` |
| 晚餐 | `daily-output/health/meal-data/YYYY-MM-DD-dinner.md` |
| 体重 | `daily-output/health/weight-data/YYYY-MM-DD-weight.md` |
| 识别原始结果 | `health-data/recognized/YYYY-MM/` |

---

## 🧪 测试方法

**测试睡眠识别：**
```bash
# 使用测试图片
./scripts/health-image-recognition.sh /path/to/sleep-screenshot.jpg sleep
```

**查看日志：**
```bash
tail -f logs/health-image-recognition.log
```

---

## ⚠️ 注意事项

1. **图片中的日期**：AI 会从图片中识别日期，如果不是当天的数据也能正确归档
2. **识别准确性**：首次识别后请检查数据是否正确，如有偏差可手动修正
3. **网络要求**：需要能访问飞书 API 和视觉模型服务
4. **隐私保护**：图片仅用于识别，不会上传到第三方服务

---

## 🔄 后续优化

- [ ] 支持更多健康数据（血压、血糖等）
- [ ] 批量识别多张图片
- [ ] 数据异常提醒（如睡眠过短、心率异常）
- [ ] 周报/月报自动生成

---

**配置时间：** 2026-03-19  
**维护者：** 城堡 🏰
