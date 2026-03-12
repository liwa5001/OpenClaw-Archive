#!/bin/bash
#
# Setup email forwarding for AgentMail
# This script configures automatic email forwarding to Feishu/iMessage
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTMAIL_DIR="${HOME}/.openclaw/workspace/skills/agentmail"
INBOX="wickedentertainment908@agentmail.to"

echo "📧 AgentMail Email Forwarding Setup"
echo "===================================="
echo ""
echo "Inbox: ${INBOX}"
echo ""

# Check if V2RayX is running
if ! pgrep -x "v2ray" > /dev/null; then
    echo "⚠️  Warning: V2RayX doesn't appear to be running."
    echo "   Please start V2RayX before using AgentMail."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check environment
echo "🔍 Checking environment..."
if [ -z "$AGENTMAIL_API_KEY" ]; then
    if [ -f "${AGENTMAIL_DIR}/.env" ]; then
        export $(cat "${AGENTMAIL_DIR}/.env" | xargs)
        echo "✅ Loaded API key from .env"
    else
        echo "❌ AGENTMAIL_API_KEY not set and .env file not found"
        exit 1
    fi
else
    echo "✅ API key already set"
fi

echo ""
echo "Select forwarding destination:"
echo "1) iMessage only"
echo "2) Feishu only"
echo "3) Both iMessage and Feishu"
read -p "Choice (1-3): " choice

case $choice in
    1)
        echo ""
        read -p "Enter iMessage destination (phone or email): " imessage_to
        FORWARD_CMD="python3 ${AGENTMAIL_DIR}/scripts/forward_email.py --inbox '${INBOX}' --to-imessage '${imessage_to}'"
        DEST_DESC="iMessage (${imessage_to})"
        ;;
    2)
        echo ""
        echo "Note: You need your Feishu Open ID."
        echo "To find it: Open Feishu → Profile → Advanced Settings → Copy Open ID"
        read -p "Enter Feishu Open ID: " feishu_id
        FORWARD_CMD="python3 ${AGENTMAIL_DIR}/scripts/forward_email.py --inbox '${INBOX}' --to-feishu '${feishu_id}'"
        DEST_DESC="Feishu (${feishu_id})"
        ;;
    3)
        echo ""
        read -p "Enter iMessage destination (phone or email): " imessage_to
        echo ""
        echo "Note: You need your Feishu Open ID."
        echo "To find it: Open Feishu → Profile → Advanced Settings → Copy Open ID"
        read -p "Enter Feishu Open ID: " feishu_id
        FORWARD_CMD="python3 ${AGENTMAIL_DIR}/scripts/forward_email.py --inbox '${INBOX}' --to-imessage '${imessage_to}' --to-feishu '${feishu_id}'"
        DEST_DESC="iMessage (${imessage_to}) and Feishu (${feishu_id})"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Select run mode:"
echo "1) Run once (manual check)"
echo "2) Daemon mode (continuous monitoring)"
echo "3) Cron job (check every 5 minutes)"
read -p "Choice (1-3): " mode

case $mode in
    1)
        echo ""
        echo "Running once..."
        eval "export $(cat ${AGENTMAIL_DIR}/.env | xargs) && ${FORWARD_CMD} --once"
        ;;
    2)
        echo ""
        read -p "Check interval in seconds (default 60): " interval
        interval=${interval:-60}
        echo ""
        echo "Starting daemon (check every ${interval}s)..."
        echo "Press Ctrl+C to stop"
        echo ""
        eval "export $(cat ${AGENTMAIL_DIR}/.env | xargs) && ${FORWARD_CMD} --daemon ${interval}"
        ;;
    3)
        echo ""
        echo "Setting up cron job..."

        # Create wrapper script
        WRAPPER="${HOME}/.openclaw/agentmail-forward.sh"
        cat > "${WRAPPER}" << EOF
#!/bin/bash
export \$(cat ${AGENTMAIL_DIR}/.env | xargs)
${FORWARD_CMD} --once >> ${HOME}/.openclaw/logs/agentmail-forward.log 2>&1
EOF
        chmod +x "${WRAPPER}"

        # Create log directory
        mkdir -p "${HOME}/.openclaw/logs"

        # Add to crontab
        CRON_JOB="*/5 * * * * ${WRAPPER}"
        (crontab -l 2>/dev/null | grep -v "agentmail-forward" || true; echo "${CRON_JOB}") | crontab -

        echo "✅ Cron job added"
        echo "   Runs every 5 minutes"
        echo "   Log: ${HOME}/.openclaw/logs/agentmail-forward.log"
        echo ""
        echo "To remove: crontab -e and delete the agentmail-forward line"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📧 Setup complete!"
echo "   Inbox: ${INBOX}"
echo "   Destination: ${DEST_DESC}"
echo ""
echo "Useful commands:"
echo "  Check inbox:     python3 ${AGENTMAIL_DIR}/scripts/check_inbox.py --inbox '${INBOX}'"
echo "  Send email:      python3 ${AGENTMAIL_DIR}/scripts/send_email.py --inbox '${INBOX}' --to 'recipient@example.com' --subject 'Test' --text 'Hello'"
echo "  Setup webhook:   python3 ${AGENTMAIL_DIR}/scripts/setup_webhook.py --list"
