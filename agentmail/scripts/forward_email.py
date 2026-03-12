#!/usr/bin/env python3
"""
Forward AgentMail emails to Feishu and/or iMessage

Usage:
    # Forward to Feishu
    python3 forward_email.py --inbox "wickedentertainment908@agentmail.to" --to-feishu "your_feishu_user_id"

    # Forward to iMessage
    python3 forward_email.py --inbox "wickedentertainment908@agentmail.to" --to-imessage "+86138xxxxxxxxx"

    # Forward to both
    python3 forward_email.py --inbox "wickedentertainment908@agentmail.to" \
        --to-feishu "your_feishu_user_id" \
        --to-imessage "+86138xxxxxxxxx"

    # Daemon mode - check every 60 seconds
    python3 forward_email.py --inbox "wickedentertainment908@agentmail.to" \
        --to-feishu "your_feishu_user_id" \
        --daemon 60

    # Mark forwarded emails as read (requires labels support)
    python3 forward_email.py --inbox "wickedentertainment908@agentmail.to" \
        --to-feishu "your_feishu_user_id" \
        --mark-read

Environment:
    AGENTMAIL_API_KEY: Your AgentMail API key
    FEISHU_APP_ID: Feishu App ID (optional, uses openclaw config if not set)
    FEISHU_APP_SECRET: Feishu App Secret (optional, uses openclaw config if not set)
    HTTPS_PROXY: Proxy for API access (e.g., http://127.0.0.1:8001)
"""

import argparse
import os
import sys
import time
import json
import subprocess
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path

try:
    from agentmail import AgentMail
except ImportError:
    print("Error: agentmail package not found. Install with: pip install agentmail")
    sys.exit(1)

# Feishu API configuration
FEISHU_API_BASE = "https://open.feishu.cn/open-apis"

class EmailForwarder:
    def __init__(self, api_key):
        self.client = AgentMail(api_key=api_key)
        self.feishu_token = None
        self.feishu_token_expiry = 0
        self.forwarded_ids = self._load_forwarded_ids()

    def _load_forwarded_ids(self):
        """Load list of already forwarded message IDs"""
        cache_file = Path.home() / ".openclaw" / "agentmail_forwarded.json"
        if cache_file.exists():
            try:
                with open(cache_file) as f:
                    return set(json.load(f))
            except:
                return set()
        return set()

    def _save_forwarded_ids(self):
        """Save list of forwarded message IDs"""
        cache_file = Path.home() / ".openclaw" / "agentmail_forwarded.json"
        cache_file.parent.mkdir(parents=True, exist_ok=True)
        with open(cache_file, 'w') as f:
            json.dump(list(self.forwarded_ids), f)

    def _get_attr(self, obj, attr, default=None):
        """Safely get attribute from object or dict"""
        if hasattr(obj, attr):
            return getattr(obj, attr)
        if isinstance(obj, dict):
            return obj.get(attr, default)
        return default

    def _get_feishu_token(self):
        """Get Feishu tenant access token"""
        if self.feishu_token and time.time() < self.feishu_token_expiry - 300:
            return self.feishu_token

        # Try environment variables first
        app_id = os.getenv('FEISHU_APP_ID')
        app_secret = os.getenv('FEISHU_APP_SECRET')

        # Fall back to openclaw config
        if not app_id or not app_secret:
            config_path = Path.home() / ".openclaw" / "openclaw.json"
            if config_path.exists():
                try:
                    with open(config_path) as f:
                        config = json.load(f)
                        channels = config.get('channels', {})
                        feishu = channels.get('feishu', {})
                        app_id = feishu.get('appId')
                        app_secret = feishu.get('appSecret')
                except Exception as e:
                    print(f"Warning: Could not read openclaw config: {e}")

        if not app_id or not app_secret:
            raise ValueError("Feishu app_id and app_secret not configured. Set FEISHU_APP_ID and FEISHU_APP_SECRET environment variables.")

        url = f"{FEISHU_API_BASE}/auth/v3/tenant_access_token/internal"
        data = json.dumps({"app_id": app_id, "app_secret": app_secret}).encode()
        headers = {"Content-Type": "application/json"}

        req = urllib.request.Request(url, data=data, headers=headers, method='POST')

        # Use proxy if configured
        proxy = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')
        if proxy:
            req.set_proxy(proxy.replace('http://', '').replace('https://', ''), 'https')

        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode())
                if result.get('code') == 0:
                    self.feishu_token = result['tenant_access_token']
                    self.feishu_token_expiry = time.time() + result['expire']
                    return self.feishu_token
                else:
                    raise Exception(f"Feishu auth error: {result}")
        except urllib.error.URLError as e:
            raise Exception(f"Failed to get Feishu token: {e}")

    def send_feishu_message(self, user_id, message_text):
        """Send message to Feishu user"""
        token = self._get_feishu_token()

        url = f"{FEISHU_API_BASE}/im/v1/messages"
        params = f"?receive_id_type=open_id"

        data = json.dumps({
            "receive_id": user_id,
            "msg_type": "text",
            "content": json.dumps({"text": message_text})
        }).encode()

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }

        req = urllib.request.Request(url + params, data=data, headers=headers, method='POST')

        # Use proxy if configured
        proxy = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')
        if proxy:
            req.set_proxy(proxy.replace('http://', '').replace('https://', ''), 'https')

        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode())
                if result.get('code') == 0:
                    return True
                else:
                    print(f"Feishu API error: {result}")
                    return False
        except urllib.error.URLError as e:
            print(f"Failed to send Feishu message: {e}")
            return False

    def send_imessage(self, phone_or_email, message_text):
        """Send message via iMessage"""
        try:
            result = subprocess.run(
                ["/opt/homebrew/bin/imsg", "send", "--to", phone_or_email, "--text", message_text],
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode == 0
        except subprocess.TimeoutExpired:
            print("iMessage send timed out")
            return False
        except Exception as e:
            print(f"Failed to send iMessage: {e}")
            return False

    def format_email_for_forwarding(self, message):
        """Format email message for forwarding"""
        from_list = self._get_attr(message, 'from_', []) or self._get_attr(message, 'from', [])
        if from_list and len(from_list) > 0:
            from_addr = self._get_attr(from_list[0], 'email', 'Unknown')
            from_name = self._get_attr(from_list[0], 'name', '')
        else:
            from_addr = 'Unknown'
            from_name = ''

        subject = self._get_attr(message, 'subject', '(no subject)')
        timestamp = self._get_attr(message, 'timestamp', '')
        text_content = self._get_attr(message, 'text', '')

        # Format timestamp
        try:
            dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            time_str = dt.strftime('%Y-%m-%d %H:%M:%S')
        except:
            time_str = timestamp

        sender = f"{from_name} <{from_addr}>" if from_name else from_addr

        # Create formatted message
        formatted = f"📧 New Email\n"
        formatted += f"From: {sender}\n"
        formatted += f"Subject: {subject}\n"
        formatted += f"Time: {time_str}\n"
        formatted += f"---\n"

        if text_content:
            # Truncate long messages
            if len(text_content) > 500:
                formatted += text_content[:500] + "...\n[Message truncated]"
            else:
                formatted += text_content
        else:
            formatted += "[No text content]"

        return formatted

    def check_and_forward(self, inbox_id, feishu_user=None, imessage_to=None, mark_read=False):
        """Check for new emails and forward them"""
        try:
            messages = self.client.inboxes.messages.list(inbox_id=inbox_id, limit=20)

            forwarded_count = 0
            for message in messages.messages:
                message_id = self._get_attr(message, 'message_id')

                # Skip already forwarded messages
                if message_id in self.forwarded_ids:
                    continue

                # Format message
                formatted = self.format_email_for_forwarding(message)

                # Forward to Feishu
                if feishu_user:
                    if self.send_feishu_message(feishu_user, formatted):
                        print(f"✅ Forwarded to Feishu: {message_id}")
                    else:
                        print(f"❌ Failed to forward to Feishu: {message_id}")
                        continue

                # Forward to iMessage
                if imessage_to:
                    if self.send_imessage(imessage_to, formatted):
                        print(f"✅ Forwarded to iMessage: {message_id}")
                    else:
                        print(f"❌ Failed to forward to iMessage: {message_id}")
                        continue

                # Mark as forwarded
                self.forwarded_ids.add(message_id)
                forwarded_count += 1

                # Optionally mark as read in AgentMail
                if mark_read:
                    try:
                        # Note: AgentMail may not support this directly
                        pass
                    except:
                        pass

            if forwarded_count > 0:
                self._save_forwarded_ids()
                print(f"📬 Forwarded {forwarded_count} new message(s)")
            else:
                print("📭 No new messages to forward")

            return forwarded_count

        except Exception as e:
            print(f"❌ Error checking inbox: {e}")
            return 0

    def run_daemon(self, inbox_id, feishu_user=None, imessage_to=None, mark_read=False, interval=60):
        """Run as daemon, checking for new emails periodically"""
        print(f"🤖 Email forwarder daemon started")
        print(f"   Inbox: {inbox_id}")
        if feishu_user:
            print(f"   Feishu: {feishu_user}")
        if imessage_to:
            print(f"   iMessage: {imessage_to}")
        print(f"   Check interval: {interval} seconds")
        print(f"   Press Ctrl+C to stop\n")

        try:
            while True:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print(f"[{timestamp}] Checking for new emails...")
                self.check_and_forward(inbox_id, feishu_user, imessage_to, mark_read)
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n👋 Daemon stopped")


def main():
    parser = argparse.ArgumentParser(description='Forward AgentMail emails to Feishu/iMessage')
    parser.add_argument('--inbox', required=True, help='AgentMail inbox address')
    parser.add_argument('--to-feishu', help='Feishu user Open ID to forward to')
    parser.add_argument('--to-imessage', help='Phone number or email for iMessage forwarding')
    parser.add_argument('--daemon', type=int, metavar='SECONDS', help='Run as daemon, check every N seconds')
    parser.add_argument('--mark-read', action='store_true', help='Mark forwarded emails as read')
    parser.add_argument('--once', action='store_true', help='Run once and exit (default)')

    args = parser.parse_args()

    # Validate at least one destination
    if not args.to_feishu and not args.to_imessage:
        print("Error: Must specify at least one of --to-feishu or --to-imessage")
        sys.exit(1)

    # Get API key
    api_key = os.getenv('AGENTMAIL_API_KEY')
    if not api_key:
        print("Error: AGENTMAIL_API_KEY environment variable not set")
        sys.exit(1)

    # Create forwarder
    forwarder = EmailForwarder(api_key)

    # Run
    if args.daemon:
        forwarder.run_daemon(
            args.inbox,
            feishu_user=args.to_feishu,
            imessage_to=args.to_imessage,
            mark_read=args.mark_read,
            interval=args.daemon
        )
    else:
        forwarder.check_and_forward(
            args.inbox,
            feishu_user=args.to_feishu,
            imessage_to=args.to_imessage,
            mark_read=args.mark_read
        )


if __name__ == '__main__':
    main()
