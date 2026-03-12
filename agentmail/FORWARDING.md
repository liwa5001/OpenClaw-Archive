# Email Forwarding

Automatically forward emails from your AgentMail inbox to Feishu and/or iMessage.

## Features

- **Real-time forwarding** - Get notified instantly when emails arrive
- **Multiple destinations** - Forward to Feishu, iMessage, or both
- **Duplicate prevention** - Tracks forwarded emails to avoid spam
- **Daemon mode** - Continuous monitoring
- **Cron support** - Periodic checks via cron job

## Quick Start

### Interactive Setup

```bash
cd ~/.openclaw/workspace/skills/agentmail
./scripts/setup-forwarding.sh
```

This wizard will guide you through:
1. Selecting destination (Feishu/iMessage/both)
2. Configuring run mode (once/daemon/cron)

### Manual Setup

#### Forward to iMessage

```bash
export $(cat .env | xargs)
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "your@email.com" \
  --once
```

#### Forward to Feishu

```bash
export $(cat .env | xargs)
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-feishu "your_feishu_open_id" \
  --once
```

#### Forward to Both

```bash
export $(cat .env | xargs)
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "your@email.com" \
  --to-feishu "your_feishu_open_id" \
  --once
```

## Run Modes

### 1. One-time Check

Check for new emails once and forward them:

```bash
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "your@email.com" \
  --once
```

### 2. Daemon Mode (Continuous)

Monitor inbox continuously and forward new emails:

```bash
python3 scripts/forward_email.py \
  --inbox "wickedentertainment908@agentmail.to" \
  --to-imessage "your@email.com" \
  --daemon 60
```

This checks every 60 seconds. Press Ctrl+C to stop.

### 3. Cron Job (Periodic)

Check every 5 minutes via cron:

```bash
# Add to crontab
*/5 * * * * cd ~/.openclaw/workspace/skills/agentmail && export $(cat .env | xargs) && python3 scripts/forward_email.py --inbox "wickedentertainment908@agentmail.to" --to-imessage "your@email.com" --once >> ~/.openclaw/logs/email-forward.log 2>&1
```

Or use the setup wizard:

```bash
./scripts/setup-forwarding.sh
# Select option 3 for cron setup
```

## Finding Your Feishu Open ID

1. Open Feishu app
2. Go to your Profile
3. Tap "Advanced Settings"
4. Tap "Copy Open ID"
5. Paste into the setup script

## iMessage Destinations

You can use:
- **Email address**: `your@email.com` (recommended)
- **Phone number**: `+86138xxxxxxxx` (with country code)

Note: The destination must be reachable via iMessage (blue bubbles, not green SMS).

## How It Works

1. **Message Tracking**: The script maintains a cache of forwarded message IDs in `~/.openclaw/agentmail_forwarded.json`
2. **Duplicate Prevention**: Already forwarded emails are skipped
3. **Formatting**: Emails are formatted with sender, subject, timestamp, and preview
4. **Proxy Support**: Uses HTTPS_PROXY from .env for API access

## Message Format

Forwarded messages look like:

```
📧 New Email
From: John Doe <john@example.com>
Subject: Meeting tomorrow
Time: 2026-03-07 15:30:00
---
Hi, just wanted to confirm our meeting tomorrow at 2pm...
```

## Troubleshooting

### "Failed to get Feishu token"

- Check your Feishu app credentials in `~/.openclaw/openclaw.json`
- Or set `FEISHU_APP_ID` and `FEISHU_APP_SECRET` environment variables

### "iMessage send timed out"

- Try using an email address instead of phone number
- Ensure the destination can receive iMessages (blue bubbles)
- Check that your Mac has iMessage configured

### "No new messages to forward"

- This is normal if no new emails have arrived
- The script tracks already-forwarded messages
- Check your inbox manually: `python3 scripts/check_inbox.py --inbox "wickedentertainment908@agentmail.to"`

### API Errors

- Ensure V2RayX is running
- Verify proxy settings in `.env`

## Security Note

⚠️ **Warning**: Email forwarding can expose sensitive information. Consider:
- Only forwarding from trusted senders
- Using webhook allowlists (see SKILL.md)
- Not forwarding emails containing passwords or sensitive data

## Files

- `scripts/forward_email.py` - Main forwarding script
- `scripts/setup-forwarding.sh` - Interactive setup wizard
- `~/.openclaw/agentmail_forwarded.json` - Cache of forwarded message IDs
