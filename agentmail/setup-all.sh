#!/bin/bash
#
# Complete AgentMail Setup for OpenClaw
# Sets up email forwarding, auto-reply, webhooks, and cron jobs
#

set -e

AGENTMAIL_DIR="${HOME}/.openclaw/workspace/skills/agentmail"
INBOX="wickedentertainment908@agentmail.to"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📧 Complete AgentMail Setup for OpenClaw         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Inbox: ${INBOX}"
echo ""

# Check V2RayX
echo -e "${BLUE}Step 1: Checking V2RayX VPN...${NC}"
if pgrep -x "v2ray" > /dev/null; then
    echo -e "${GREEN}✓${NC} V2RayX is running"
else
    echo -e "${YELLOW}⚠${NC}  V2RayX not detected. Please start it before continuing."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# Load environment
echo ""
echo -e "${BLUE}Step 2: Loading environment...${NC}"
if [ -f "${AGENTMAIL_DIR}/.env" ]; then
    export $(cat "${AGENTMAIL_DIR}/.env" | xargs)
    echo -e "${GREEN}✓${NC} Environment loaded"
else
    echo -e "${YELLOW}✗${NC} .env file not found"
    exit 1
fi

# Test API connection
echo ""
echo -e "${BLUE}Step 3: Testing API connection...${NC}"
cd "${AGENTMAIL_DIR}"
python3 -c "
from agentmail import AgentMail
import os
client = AgentMail(api_key=os.getenv('AGENTMAIL_API_KEY'))
inbox = client.inboxes.get('${INBOX}')
print(f'✓ Connected: {inbox.inbox_id}')
" && echo -e "${GREEN}✓${NC} API connection successful" || {
    echo -e "${YELLOW}✗${NC} API connection failed. Check V2RayX."
    exit 1
}

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Feature selection
echo "Select features to enable:"
echo ""
echo "1) 📱 Email Forwarding"
echo "   → Forward emails to iMessage/Feishu"
echo ""
echo "2) 🤖 Auto-Reply Bot"
echo "   → Automatically respond to incoming emails"
echo ""
echo "3) 🌐 Webhook Receiver"
echo "   → Real-time notifications (requires ngrok)"
echo ""
echo "4) ⏰ Cron Job (Auto-check every 5 min)"
echo "   → Background email checking"
echo ""
echo "5) 🚀 ALL OF THE ABOVE"
echo ""
echo "6) Exit"
echo ""
read -p "Choice (1-6): " main_choice

case $main_choice in
    1)
        echo ""
        echo "📱 Setting up Email Forwarding..."
        ./scripts/setup-forwarding.sh
        ;;
    2)
        echo ""
        echo "🤖 Setting up Auto-Reply Bot..."
        read -p "Enter custom reply message (press Enter for default): " reply_msg
        if [ -n "$reply_msg" ]; then
            echo "Starting auto-reply daemon..."
            python3 scripts/auto_reply.py --inbox "$INBOX" --template "$reply_msg" --daemon 60
        else
            echo "Starting auto-reply daemon with default message..."
            python3 scripts/auto_reply.py --inbox "$INBOX" --daemon 60
        fi
        ;;
    3)
        echo ""
        echo "🌐 Setting up Webhook Receiver..."
        read -p "Forward to iMessage (+8615618478118)? (y/n): " do_imessage
        read -p "Enable auto-reply? (y/n): " do_reply

        IMES=""
        REPLY=""
        [[ $do_imessage =~ ^[Yy]$ ]] && IMES="--to-imessage +8615618478118"
        [[ $do_reply =~ ^[Yy]$ ]] && REPLY="--auto-reply"

        echo ""
        echo "Starting webhook receiver on port 3000..."
        echo "In another terminal, run: ngrok http 3000"
        echo "Then register the webhook URL"
        echo ""
        python3 scripts/webhook_receiver.py --inbox "$INBOX" $IMES $REPLY
        ;;
    4)
        echo ""
        echo "⏰ Setting up Cron Job..."
        ./scripts/setup-cron.sh
        ;;
    5)
        echo ""
        echo "🚀 Setting up ALL features..."
        echo ""

        # 1. Forwarding
        echo -e "${BLUE}[1/4] Email Forwarding${NC}"
        echo "Forwarding to: iMessage (+8615618478118)"
        read -p "Also forward to Feishu? Enter Open ID (or press Enter to skip): " feishu_id

        # 2. Auto-reply
        echo ""
        echo -e "${BLUE}[2/4] Auto-Reply Bot${NC}"
        read -p "Enable auto-reply? (y/n): " enable_reply
        if [[ $enable_reply =~ ^[Yy]$ ]]; then
            read -p "Custom reply message (press Enter for default): " custom_reply
        fi

        # 3. Cron job
        echo ""
        echo -e "${BLUE}[3/4] Cron Job Setup${NC}"
        read -p "Enable automatic checking every 5 minutes? (y/n): " enable_cron

        # 4. Webhook
        echo ""
        echo -e "${BLUE}[4/4] Webhook Setup${NC}"
        echo "Note: Webhook requires manual ngrok setup"
        echo "You'll need to:"
        echo "  1. Start webhook receiver: python3 scripts/webhook_receiver.py --inbox '$INBOX' --to-imessage '+8615618478118'"
        echo "  2. Run ngrok: ngrok http 3000"
        echo "  3. Register webhook: python3 scripts/setup_webhook.py --create --url 'YOUR_NGROK_URL/webhook'"
        echo ""

        # Create log directory
        mkdir -p "${HOME}/.openclaw/logs"

        # Setup forwarding wrapper
        if [[ $enable_cron =~ ^[Yy]$ ]]; then
            echo "Creating cron job wrappers..."

            FORWARD_OPTS="--inbox '${INBOX}' --to-imessage '+8615618478118'"
            [ -n "$feishu_id" ] && FORWARD_OPTS="${FORWARD_OPTS} --to-feishu '${feishu_id}'"

            # Forwarding wrapper
            cat > "${HOME}/.openclaw/cron-forward.sh" << EOF
#!/bin/bash
export \$(cat ${AGENTMAIL_DIR}/.env | xargs)
cd ${AGENTMAIL_DIR}
python3 scripts/forward_email.py ${FORWARD_OPTS} --once >> ${HOME}/.openclaw/logs/forward.log 2>&1
EOF
            chmod +x "${HOME}/.openclaw/cron-forward.sh"

            # Add to crontab
            (crontab -l 2>/dev/null | grep -v "cron-forward.sh" || true; echo "*/5 * * * * ${HOME}/.openclaw/cron-forward.sh") | crontab -
            echo -e "${GREEN}✓${NC} Cron job installed (checks every 5 minutes)"
        fi

        # Summary
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✅ ALL FEATURES CONFIGURED!                     ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "📧 Inbox: ${INBOX}"
        echo "📱 iMessage: +8615618478118"
        [ -n "$feishu_id" ] && echo "💬 Feishu: ${feishu_id}"
        [[ $enable_reply =~ ^[Yy]$ ]] && echo "🤖 Auto-reply: Enabled"
        [[ $enable_cron =~ ^[Yy]$ ]] && echo "⏰ Cron job: Every 5 minutes"
        echo ""
        echo "Logs: ${HOME}/.openclaw/logs/"
        echo ""
        echo "Quick commands:"
        echo "  Check inbox:     python3 scripts/check_inbox.py --inbox '${INBOX}'"
        echo "  Send email:      python3 scripts/send_email.py --inbox '${INBOX}' --to 'recipient@example.com' --subject 'Test' --text 'Hello'"
        echo "  View logs:       tail -f ~/.openclaw/logs/forward.log"
        [[ $enable_cron =~ ^[Yy]$ ]] && echo "  Remove cron:     crontab -e (delete cron-forward line)"
        echo ""
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Setup complete!${NC}"
