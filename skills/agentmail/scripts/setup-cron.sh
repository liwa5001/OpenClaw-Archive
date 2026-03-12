#!/bin/bash
#
# Setup cron job for AgentMail email checking
# Runs every 5 minutes to check for new emails
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTMAIL_DIR="${HOME}/.openclaw/workspace/skills/agentmail"
INBOX="wickedentertainment908@agentmail.to"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📧 AgentMail Cron Job Setup${NC}"
echo "============================="
echo ""
echo "This will set up automatic email checking every 5 minutes."
echo ""

# Check if cron is available
if ! command -v crontab &> /dev/null; then
    echo "Error: crontab command not found. Please install cron."
    exit 1
fi

# Select services to enable
echo "Select services to enable:"
echo "1) Forward to iMessage only (+8615618478118)"
echo "2) Forward to Feishu only"
echo "3) Forward to both"
echo "4) Auto-reply bot only"
echo "5) Forward + Auto-reply"
read -p "Choice (1-5): " choice

IMESSAGE_TO="+8615618478118"
FEISHU_ID=""
ENABLE_FORWARD=false
ENABLE_AUTOREPLY=false

case $choice in
    1)
        ENABLE_FORWARD=true
        echo -e "${GREEN}✓${NC} iMessage forwarding enabled: $IMESSAGE_TO"
        ;;
    2)
        read -p "Enter Feishu Open ID: " FEISHU_ID
        ENABLE_FORWARD=true
        echo -e "${GREEN}✓${NC} Feishu forwarding enabled: $FEISHU_ID"
        ;;
    3)
        read -p "Enter Feishu Open ID (optional, press Enter to skip): " FEISHU_ID
        ENABLE_FORWARD=true
        echo -e "${GREEN}✓${NC} iMessage forwarding enabled: $IMESSAGE_TO"
        if [ -n "$FEISHU_ID" ]; then
            echo -e "${GREEN}✓${NC} Feishu forwarding enabled: $FEISHU_ID"
        fi
        ;;
    4)
        ENABLE_AUTOREPLY=true
        echo -e "${GREEN}✓${NC} Auto-reply bot enabled"
        ;;
    5)
        read -p "Enter Feishu Open ID (optional, press Enter to skip): " FEISHU_ID
        ENABLE_FORWARD=true
        ENABLE_AUTOREPLY=true
        echo -e "${GREEN}✓${NC} iMessage forwarding enabled: $IMESSAGE_TO"
        echo -e "${GREEN}✓${NC} Auto-reply bot enabled"
        if [ -n "$FEISHU_ID" ]; then
            echo -e "${GREEN}✓${NC} Feishu forwarding enabled: $FEISHU_ID"
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Create log directory
mkdir -p "${HOME}/.openclaw/logs"

# Build cron commands
CRON_COMMANDS=""

# Forwarding job
if [ "$ENABLE_FORWARD" = true ]; then
    FORWARD_OPTS="--inbox '${INBOX}' --to-imessage '${IMESSAGE_TO}'"
    if [ -n "$FEISHU_ID" ]; then
        FORWARD_OPTS="${FORWARD_OPTS} --to-feishu '${FEISHU_ID}'"
    fi

    FORWARD_SCRIPT="${AGENTMAIL_DIR}/scripts/forward_email.py"
    FORWARD_WRAPPER="${HOME}/.openclaw/cron-forward.sh"

    cat > "${FORWARD_WRAPPER}" << EOF
#!/bin/bash
export \$(cat ${AGENTMAIL_DIR}/.env | xargs)
cd ${AGENTMAIL_DIR}
python3 ${FORWARD_SCRIPT} ${FORWARD_OPTS} --once >> ${HOME}/.openclaw/logs/forward.log 2>&1
EOF
    chmod +x "${FORWARD_WRAPPER}"

    CRON_COMMANDS="${CRON_COMMANDS}*/5 * * * * ${FORWARD_WRAPPER}\n"
    echo ""
    echo "Forwarding job created: ${FORWARD_WRAPPER}"
fi

# Auto-reply job
if [ "$ENABLE_AUTOREPLY" = true ]; then
    REPLY_SCRIPT="${AGENTMAIL_DIR}/scripts/auto_reply.py"
    REPLY_WRAPPER="${HOME}/.openclaw/cron-reply.sh"

    cat > "${REPLY_WRAPPER}" << EOF
#!/bin/bash
export \$(cat ${AGENTMAIL_DIR}/.env | xargs)
cd ${AGENTMAIL_DIR}
python3 ${REPLY_SCRIPT} --inbox '${INBOX}' --once >> ${HOME}/.openclaw/logs/reply.log 2>&1
EOF
    chmod +x "${REPLY_WRAPPER}"

    CRON_COMMANDS="${CRON_COMMANDS}*/5 * * * * ${REPLY_WRAPPER}\n"
    echo "Auto-reply job created: ${REPLY_WRAPPER}"
fi

# Install cron jobs
echo ""
echo "Installing cron jobs..."

# Get current crontab, remove old agentmail entries, add new ones
(crontab -l 2>/dev/null | grep -v "cron-forward.sh" | grep -v "cron-reply.sh" || true; echo -e "${CRON_COMMANDS}") | crontab -

echo ""
echo -e "${GREEN}✅ Cron jobs installed successfully!${NC}"
echo ""
echo "Schedule: Every 5 minutes"
echo "Logs: ${HOME}/.openclaw/logs/"
echo ""
echo "To view logs:"
echo "  tail -f ~/.openclaw/logs/forward.log"
echo "  tail -f ~/.openclaw/logs/reply.log"
echo ""
echo "To remove cron jobs:"
echo "  crontab -e"
echo "  Delete the lines containing cron-forward.sh and cron-reply.sh"
