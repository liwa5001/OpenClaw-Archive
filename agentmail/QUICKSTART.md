# 🎉 AgentMail Setup Complete!

## ✅ What's Configured

### 📧 Inbox
- **Email**: `wickedentertainment908@agentmail.to`
- **API**: Connected via V2RayX VPN
- **Status**: ✅ Fully Operational

### 📱 1. Email Forwarding (WORKING)
**Files**: `scripts/forward_email.py`, `scripts/setup-forwarding.sh`

**Status**: ✅ Tested & Working
- iMessage: `+8615618478118` ✅
- Feishu: Ready (needs your Open ID)

**Usage**:
```bash
# Forward once
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --once

# Daemon mode (continuous)
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --daemon 60
```

---

### 🤖 2. Auto-Reply Bot (WORKING)
**File**: `scripts/auto_reply.py`

**Status**: ✅ Tested & Working
- Auto-replied to: `liwa5001@hotmail.com`
- Skipped own emails

**Features**:
- Won't reply to own emails
- Won't reply to noreply addresses
- Won't reply to newsletters
- Tracks replied messages

**Usage**:
```bash
# Run once
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --once

# Daemon mode
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --daemon 60

# Custom message
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --template "Thanks! I'll reply soon." \
  --daemon 60
```

---

### 🌐 3. Webhook Receiver (READY)
**File**: `scripts/webhook_receiver.py`

**Status**: ✅ Ready (requires ngrok for external access)

**Setup**:
```bash
# Terminal 1: Start webhook receiver
python3 scripts/webhook_receiver.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --port 3000

# Terminal 2: Start ngrok
ngrok http 3000

# Terminal 3: Register webhook (replace with your ngrok URL)
python3 scripts/setup_webhook.py \
  --create \
  --url "https://YOUR_NGROK_URL/webhook" \
  --events "message.received"
```

---

### ⏰ 4. Cron Job (READY)
**Files**: `scripts/setup-cron.sh`, `setup-all.sh`

**Status**: ✅ Ready

**Quick Setup**:
```bash
./scripts/setup-cron.sh
# Follow prompts to select services
```

**Manual Setup**:
```bash
# Create forwarding cron job
cat > ~/.openclaw/cron-forward.sh << 'EOF'
#!/bin/bash
export $(cat ~/.openclaw/workspace/skills/agentmail/.env | xargs)
cd ~/.openclaw/workspace/skills/agentmail
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --once >> ~/.openclaw/logs/forward.log 2>&1
EOF
chmod +x ~/.openclaw/cron-forward.sh

# Install cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/.openclaw/cron-forward.sh") | crontab -
```

---

## 📁 All Files Created

```
~/.openclaw/workspace/skills/agentmail/
├── .env                              # API key + proxy config
├── SETUP.md                          # Complete documentation ⭐
├── SKILL.md                          # Original skill docs
├── FORWARDING.md                     # Forwarding guide
├── QUICKSTART.md                     # This file
├── setup-all.sh                      # Master setup script ⭐
├── references/
│   ├── API.md
│   ├── WEBHOOKS.md
│   └── EXAMPLES.md
└── scripts/
    ├── send_email.py                 # Send emails
    ├── check_inbox.py                # Check/manage inbox
    ├── forward_email.py              # Forward to iMessage/Feishu ⭐
    ├── auto_reply.py                 # Auto-reply bot ⭐
    ├── webhook_receiver.py           # Webhook server ⭐
    ├── setup_webhook.py              # Webhook management
    ├── setup-forwarding.sh           # Interactive forwarding setup
    ├── setup-cron.sh                 # Cron job setup
    └── setup-all.sh                  # Master setup (symlink)
```

---

## 🚀 Quick Commands

### Check Inbox
```bash
cd ~/.openclaw/workspace/skills/agentmail
export $(cat .env | xargs)
python3 scripts/check_inbox.py --inbox "wickedentertainment908@agentmail.to"
```

### Send Email
```bash
python3 scripts/send_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to "recipient@example.com" \
  --subject "Hello" \
  --text "Message"
```

### Forward to iMessage
```bash
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --once
```

### Auto-Reply Bot
```bash
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --daemon 60
```

### View Logs
```bash
tail -f ~/.openclaw/logs/forward.log
tail -f ~/.openclaw/logs/reply.log
```

---

## 🔧 Important Notes

### V2RayX Required
**Always ensure V2RayX is running before using AgentMail!**

Verify:
```bash
curl -x http://127.0.0.1:8001 https://ifconfig.io
# Should show US IP, not China
```

### Finding Feishu Open ID
1. Open Feishu app
2. Profile → Advanced Settings
3. Copy Open ID

### Cache Files
These store forwarded/replied message IDs to prevent duplicates:
- `~/.openclaw/agentmail_forwarded.json`
- `~/.openclaw/agentmail_replied.json`

To reset: Just delete these files.

---

## 📊 Test Results

| Feature | Status | Test Result |
|---------|--------|-------------|
| API Connection | ✅ | Connected to wickedentertainment908@agentmail.to |
| Send Email | ✅ | Test email sent successfully |
| iMessage Forward | ✅ | 2 messages forwarded to +8615618478118 |
| Auto-Reply | ✅ | Replied to liwa5001@hotmail.com |
| Feishu Forward | ⏳ | Ready (needs Open ID) |
| Webhook | ⏳ | Ready (needs ngrok) |
| Cron Job | ⏳ | Ready (run setup-cron.sh) |

---

## 🎯 Next Steps

1. **Run the master setup**:
   ```bash
   ./setup-all.sh
   ```

2. **Or set up features individually**:
   - Forwarding: `./scripts/setup-forwarding.sh`
   - Cron job: `./scripts/setup-cron.sh`
   - Webhook: Follow WEBHOOKS.md

3. **Add Feishu forwarding** (optional):
   - Get your Feishu Open ID
   - Add to forwarding: `--to-feishu "YOUR_OPEN_ID"`

4. **Install ngrok** for webhook:
   ```bash
   brew install ngrok
   ngrok config add-authtoken YOUR_TOKEN
   ```

---

## 📞 Support

- Full docs: `SETUP.md`
- API reference: `references/API.md`
- Webhook guide: `references/WEBHOOKS.md`
- Console: https://console.agentmail.to
