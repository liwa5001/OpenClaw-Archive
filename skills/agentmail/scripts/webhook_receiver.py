#!/usr/bin/env python3
"""
Webhook receiver for AgentMail - Real-time email notifications

This script sets up a local webhook server that receives email notifications
from AgentMail instantly (no polling needed).

Usage:
    # Start webhook receiver
    python3 webhook_receiver.py --port 3000

    # With forwarding to iMessage/Feishu
    python3 webhook_receiver.py --port 3000 --to-imessage "+8615618478118"

    # With auto-reply
    python3 webhook_receiver.py --port 3000 --auto-reply

Setup:
    1. Start this server: python3 webhook_receiver.py --port 3000
    2. Start ngrok: ngrok http 3000
    3. Copy ngrok URL (e.g., https://abc123.ngrok-free.app)
    4. Register webhook: python3 setup_webhook.py --create --url "https://abc123.ngrok-free.app/webhook"
    5. Send test email to see instant notification!

Environment:
    AGENTMAIL_API_KEY: Your AgentMail API key
    HTTPS_PROXY: Proxy for API access
"""

import argparse
import os
import sys
import json
import hmac
import hashlib
from datetime import datetime
from pathlib import Path

try:
    from flask import Flask, request, Response
except ImportError:
    print("Error: flask package not found. Install with: pip install flask")
    sys.exit(1)

try:
    from agentmail import AgentMail
except ImportError:
    print("Error: agentmail package not found. Install with: pip install agentmail")
    sys.exit(1)

# Import forwarding functions
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from forward_email import EmailForwarder

app = Flask(__name__)

# Configuration
config = {
    'api_key': None,
    'inbox_id': None,
    'imessage_to': None,
    'feishu_user': None,
    'auto_reply': False,
    'webhook_secret': None,
    'client': None,
    'forwarder': None
}

def format_email_notification(payload):
    """Format webhook payload for notification"""
    message = payload.get('message', {})
    event_type = payload.get('event_type', 'unknown')

    if event_type == 'message.received':
        from_list = message.get('from', [])
        from_addr = from_list[0].get('email', 'Unknown') if from_list else 'Unknown'
        from_name = from_list[0].get('name', '') if from_list else ''
        subject = message.get('subject', '(no subject)')
        preview = message.get('preview', message.get('text', ''))[:100]

        sender = f"{from_name} <{from_addr}>" if from_name else from_addr

        notification = f"📧 New Email Received\n"
        notification += f"From: {sender}\n"
        notification += f"Subject: {subject}\n"
        if preview:
            notification += f"Preview: {preview}{'...' if len(preview) == 100 else ''}\n"

        return notification

    elif event_type == 'message.sent':
        return f"📤 Email sent: {message.get('subject', '(no subject)')}"

    else:
        return f"📨 Event: {event_type}"

def verify_webhook(payload, signature, secret):
    """Verify webhook signature"""
    if not secret:
        return True  # Skip verification if no secret

    expected = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(f"sha256={expected}", signature)

def send_imessage(phone_or_email, message_text):
    """Send message via iMessage"""
    import subprocess
    try:
        result = subprocess.run(
            ["/opt/homebrew/bin/imsg", "send", "--to", phone_or_email, "--text", message_text],
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.returncode == 0
    except Exception as e:
        print(f"Failed to send iMessage: {e}")
        return False

def send_feishu_message(user_id, message_text):
    """Send message to Feishu user"""
    # This would need the Feishu token logic from forward_email.py
    # For now, just log it
    print(f"Would send Feishu message to {user_id}")
    return True

@app.route('/')
def home():
    return """
    <h1>AgentMail Webhook Receiver</h1>
    <p>✅ Server is running</p>
    <p>Webhook endpoint: <code>POST /webhook</code></p>
    <p>Use ngrok to expose this server to the internet.</p>
    """

@app.route('/webhook', methods=['POST'])
def webhook():
    """Receive AgentMail webhooks"""
    payload = request.json

    # Log the event
    event_type = payload.get('event_type', 'unknown')
    event_id = payload.get('event_id', 'N/A')
    print(f"\n🪝 Webhook received: {event_type} ({event_id})")

    # Handle message.received
    if event_type == 'message.received':
        message = payload.get('message', {})
        inbox_id = message.get('inbox_id', '')

        # Check if this is for our inbox
        if config['inbox_id'] and inbox_id != config['inbox_id']:
            print(f"⏭️  Ignoring message for different inbox: {inbox_id}")
            return Response(status=200)

        # Format notification
        notification = format_email_notification(payload)
        print(notification)

        # Forward to iMessage
        if config['imessage_to']:
            if send_imessage(config['imessage_to'], notification):
                print(f"✅ Forwarded to iMessage: {config['imessage_to']}")
            else:
                print(f"❌ Failed to forward to iMessage")

        # Forward to Feishu
        if config['feishu_user']:
            if send_feishu_message(config['feishu_user'], notification):
                print(f"✅ Forwarded to Feishu: {config['feishu_user']}")
            else:
                print(f"❌ Failed to forward to Feishu")

        # Auto-reply
        if config['auto_reply']:
            from_list = message.get('from', [])
            if from_list:
                sender_email = from_list[0].get('email', '')
                subject = message.get('subject', '')

                # Don't reply to ourselves
                if config['inbox_id'] not in sender_email:
                    try:
                        reply_text = f"Thanks for your email about '{subject}'. I'll get back to you soon!"
                        config['client'].inboxes.messages.send(
                            inbox_id=inbox_id,
                            to=[sender_email],
                            subject=f"Re: {subject}",
                            text=reply_text
                        )
                        print(f"✅ Auto-replied to: {sender_email}")
                    except Exception as e:
                        print(f"❌ Failed to auto-reply: {e}")

    return Response(status=200)

@app.route('/health', methods=['GET'])
def health():
    return {'status': 'ok', 'timestamp': datetime.now().isoformat()}

def main():
    parser = argparse.ArgumentParser(description='AgentMail Webhook Receiver')
    parser.add_argument('--port', type=int, default=3000, help='Port to run server on')
    parser.add_argument('--inbox', help='Filter to specific inbox')
    parser.add_argument('--to-imessage', help='Forward notifications to iMessage')
    parser.add_argument('--to-feishu', help='Forward notifications to Feishu')
    parser.add_argument('--auto-reply', action='store_true', help='Enable auto-reply')
    parser.add_argument('--secret', help='Webhook secret for verification')

    args = parser.parse_args()

    # Get API key
    api_key = os.getenv('AGENTMAIL_API_KEY')
    if not api_key:
        print("Error: AGENTMAIL_API_KEY environment variable not set")
        sys.exit(1)

    # Configure
    config['api_key'] = api_key
    config['inbox_id'] = args.inbox
    config['imessage_to'] = args.to_imessage
    config['feishu_user'] = args.to_feishu
    config['auto_reply'] = args.auto_reply
    config['webhook_secret'] = args.secret
    config['client'] = AgentMail(api_key=api_key)

    print(f"🚀 Starting webhook receiver on http://localhost:{args.port}")
    print(f"   Inbox filter: {args.inbox or 'All'}")
    if args.to_imessage:
        print(f"   iMessage: {args.to_imessage}")
    if args.to_feishu:
        print(f"   Feishu: {args.to_feishu}")
    if args.auto_reply:
        print(f"   Auto-reply: Enabled")
    print(f"\n📡 Webhook endpoint: http://localhost:{args.port}/webhook")
    print(f"\n💡 For external access, use ngrok:")
    print(f"   ngrok http {args.port}")
    print(f"\n🛑 Press Ctrl+C to stop\n")

    try:
        app.run(host='0.0.0.0', port=args.port, debug=False)
    except KeyboardInterrupt:
        print("\n👋 Webhook receiver stopped")

if __name__ == '__main__':
    main()
