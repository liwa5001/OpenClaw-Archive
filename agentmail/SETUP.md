# AgentMail Complete Setup for OpenClaw

## Account Information
- **Email**: `wickedentertainment908@agentmail.to`
- **API Key**: Configured in `.env`
- **Status**: ✅ **FULLY OPERATIONAL**

## Quick Start

Run the master setup script:
```bash
cd ~/.openclaw/workspace/skills/agentmail
./setup-all.sh
```

Or set up features individually using the guides below.

---

## 📋 Feature Overview

| Feature | Script | Purpose |
|---------|--------|---------|
| 📧 **Check Inbox** | `check_inbox.py` | View emails, threads, monitor in real-time |
| 📤 **Send Email** | `send_email.py` | Send emails with attachments |
| 📱 **Forward to iMessage/Feishu** | `forward_email.py` | Get notified on your phone |
| 🤖 **Auto-Reply Bot** | `auto_reply.py` | Automatically respond to emails |
| 🌐 **Webhook Receiver** | `webhook_receiver.py` | Real-time notifications (no polling) |
| ⏰ **Cron Job** | `setup-cron.sh` | Background checking every 5 min |

---

## 📱 1. Email Forwarding to iMessage/Feishu

Get instant notifications when emails arrive.

### Quick Setup

```bash
# Interactive setup wizard
./scripts/setup-forwarding.sh
```

### Manual Usage

**Forward to iMessage:**
```bash
export $(cat .env | xargs)
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --once
```

**Forward to Feishu:**
```bash
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-feishu "YOUR_FEISHU_OPEN_ID" \
  --once
```

**Forward to both:**
```bash
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --to-feishu "YOUR_FEISHU_OPEN_ID" \
  --once
```

**Daemon mode (continuous):**
```bash
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --daemon 60
```

### Finding Your Feishu Open ID

1. Open Feishu app
2. Go to Profile → Advanced Settings
3. Tap "Copy Open ID"

---

## 🤖 2. Auto-Reply Bot

Automatically respond to incoming emails.

### Usage

**Default auto-reply:**
```bash
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --once
```

**Custom reply message:**
```bash
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --template "Thanks for your email! I'll respond within 24 hours." \
  --once
```

**Daemon mode:**
```bash
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --daemon 60
```

### Features

- ✅ Won't reply to your own emails
- ✅ Won't reply to noreply addresses
- ✅ Skips newsletters/marketing emails
- ✅ Tracks replied messages (no duplicates)

---

## 🌐 3. Webhook Receiver (Real-Time)

Receive instant notifications when emails arrive - no polling needed!

### Setup Steps

**Step 1: Start webhook receiver**
```bash
python3 scripts/webhook_receiver.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "+8615618478118" \
  --port 3000
```

**Step 2: Install ngrok**
```bash
brew install ngrok
ngrok config add-authtoken YOUR_NGROK_TOKEN
```

**Step 3: Start ngrok tunnel**
```bash
ngrok http 3000
# Copy the https URL (e.g., https://abc123.ngrok-free.app)
```

**Step 4: Register webhook**
```bash
python3 scripts/setup_webhook.py \
  --create \
  --url "https://abc123.ngrok-free.app/webhook" \
  --events "message.received"
```

**Step 5: Test!**
Send an email to `wickedentertainment908@agentmail.to` and watch it appear instantly.

### Webhook Options

```bash
# With iMessage forwarding
python3 scripts/webhook_receiver.py --inbox "wickedentertainment908@agentmail.to" --to-imessage "+8615618478118"

# With auto-reply
python3 scripts/webhook_receiver.py --inbox "wickedentertainment908@agentmail.to" --to-imessage "+8615618478118" --auto-reply

# With Feishu
python3 scripts/webhook_receiver.py --inbox "wickedentertainment908@agentmail.to" --to-feishu "YOUR_OPEN_ID"
```

---

## ⏰ 4. Cron Job (Background Checking)

Automatically check for emails every 5 minutes.

### Interactive Setup

```bash
./scripts/setup-cron.sh
```

### Manual Setup

**Forward emails via cron:**
```bash
# Create wrapper script
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

# Add to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/.openclaw/cron-forward.sh") | crontab -
```

**Auto-reply via cron:**
```bash
cat > ~/.openclaw/cron-reply.sh << 'EOF'
#!/bin/bash
export $(cat ~/.openclaw/workspace/skills/agentmail/.env | xargs)
cd ~/.openclaw/workspace/skills/agentmail
python3 scripts/auto_reply.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --once >> ~/.openclaw/logs/reply.log 2>&1
EOF
chmod +x ~/.openclaw/cron-reply.sh

(crontab -l 2>/dev/null; echo "*/5 * * * * ~/.openclaw/cron-reply.sh") | crontab -
```

### View Logs

```bash
# Forwarding log
tail -f ~/.openclaw/logs/forward.log

# Auto-reply log
tail -f ~/.openclaw/logs/reply.log
```

### Remove Cron Jobs

```bash
crontab -e
# Delete lines containing cron-forward.sh or cron-reply.sh
```

---

## 📧 Basic Email Operations

### Send Email

```bash
# Simple text email
python3 scripts/send_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to "recipient@example.com" \
  --subject "Hello" \
  --text "Message body"

# With HTML
python3 scripts/send_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to "recipient@example.com" \
  --subject "Hello" \
  --html "<p><strong>Message</strong> body</p>"

# With attachment
python3 scripts/send_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to "recipient@example.com" \
  --subject "Document" \
  --text "See attached" \
  --attach "/path/to/file.pdf"

# Multiple recipients
python3 scripts/send_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to "user1@example.com,user2@example.com" \
  --cc "boss@example.com" \
  --subject "Hello" \
  --text "Message"
```

### Check Inbox

```bash
# List recent messages
python3 scripts/check_inbox.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --limit 10

# Get specific message
python3 scripts/check_inbox.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --message "msg_123abc"

# List threads
python3 scripts/check_inbox.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --threads

# Monitor for new messages (poll every 30 seconds)
python3 scripts/check_inbox.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --monitor 30
```

---

## 🔧 Important: VPN Required

**V2RayX must be running for API access!**

The AgentMail API blocks Chinese IPs. Your V2RayX is configured on port 8001 and is automatically used via the proxy settings in `.env`.

**Verify VPN is working:**
```bash
curl -x http://127.0.0.1:8001 https://ifconfig.io
# Should show a non-China IP (e.g., US IP)
```

---

## 📁 File Structure

```
~/.openclaw/workspace/skills/agentmail/
├── .env                          # API key + proxy config
├── SETUP.md                      # This file
├── SKILL.md                      # Original skill documentation
├── FORWARDING.md                 # Forwarding-specific docs
├── references/
│   ├── API.md                    # API reference
│   ├── WEBHOOKS.md               # Webhook guide
│   └── EXAMPLES.md               # Usage examples
└── scripts/
    ├── send_email.py             # Send emails
    ├── check_inbox.py            # Check/manage inbox
    ├── forward_email.py          # Forward to iMessage/Feishu
    ├── auto_reply.py             # Auto-reply bot
    ├── webhook_receiver.py       # Webhook server
    ├── setup_webhook.py          # Webhook management
    ├── setup-forwarding.sh       # Interactive forwarding setup
    ├── setup-cron.sh             # Cron job setup
    └── setup-all.sh              # Master setup script
```

---

## 🛠️ Troubleshooting

### "403 Forbidden" Error
- **Cause**: V2RayX not running
- **Fix**: Start V2RayX, verify with `curl -x http://127.0.0.1:8001 https://ifconfig.io`

### "iMessage send timed out"
- **Cause**: Invalid phone number format or not iMessage capable
- **Fix**: Use email address format (e.g., `liwang@88.com`) or ensure number can receive iMessages

### "Failed to get Feishu token"
- **Cause**: Feishu app credentials not configured
- **Fix**: Check `~/.openclaw/openclaw.json` or set `FEISHU_APP_ID` and `FEISHU_APP_SECRET`

### "No module named 'agentmail'"
```bash
pip install agentmail python-dotenv flask
```

### Clear forwarding cache
```bash
rm ~/.openclaw/agentmail_forwarded.json
rm ~/.openclaw/agentmail_replied.json
```

---

## 🔒 Security Notes

1. **Webhook Security**: When using webhooks, implement sender allowlists (see SKILL.md)
2. **API Key**: Never share your `.env` file or API key
3. **Email Content**: Be cautious about forwarding emails containing sensitive information
4. **Auto-Reply**: The bot won't reply to noreply addresses or newsletters

---

## 📞 Support

- AgentMail Console: https://console.agentmail.to
- API Documentation: See `references/API.md`
- Webhook Guide: See `references/WEBHOOKS.md`
