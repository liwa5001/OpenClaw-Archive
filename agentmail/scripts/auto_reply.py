#!/usr/bin/env python3
"""
Auto-reply bot for AgentMail

Automatically responds to incoming emails based on rules.

Usage:
    # Run once (check and reply)
    python3 auto_reply.py --inbox "wickedentertainment908@agentmail.to"

    # Daemon mode (continuous monitoring)
    python3 auto_reply.py --inbox "wickedentertainment908@agentmail.to" --daemon 60

    # Custom reply template
    python3 auto_reply.py --inbox "wickedentertainment908@agentmail.to" \
        --template "Thanks for your email! I'll respond within 24 hours."

Environment:
    AGENTMAIL_API_KEY: Your AgentMail API key
    HTTPS_PROXY: Proxy for API access (e.g., http://127.0.0.1:8001)
"""

import argparse
import os
import sys
import time
import json
import re
from datetime import datetime
from pathlib import Path

try:
    from agentmail import AgentMail
except ImportError:
    print("Error: agentmail package not found. Install with: pip install agentmail")
    sys.exit(1)

class AutoReplyBot:
    def __init__(self, api_key, inbox_id, reply_template=None):
        self.client = AgentMail(api_key=api_key)
        self.inbox_id = inbox_id
        self.reply_template = reply_template or self._default_template()
        self.replied_ids = self._load_replied_ids()

    def _default_template(self):
        return """Hello,

Thank you for your email regarding "{subject}".

This is an automated response. I've received your message and will get back to you as soon as possible.

Best regards,
OpenClaw Agent
"""

    def _load_replied_ids(self):
        """Load list of already replied message IDs"""
        cache_file = Path.home() / ".openclaw" / "agentmail_replied.json"
        if cache_file.exists():
            try:
                with open(cache_file) as f:
                    return set(json.load(f))
            except:
                return set()
        return set()

    def _save_replied_ids(self):
        """Save list of replied message IDs"""
        cache_file = Path.home() / ".openclaw" / "agentmail_replied.json"
        cache_file.parent.mkdir(parents=True, exist_ok=True)
        with open(cache_file, 'w') as f:
            json.dump(list(self.replied_ids), f)

    def _get_attr(self, obj, attr, default=None):
        """Safely get attribute from object or dict"""
        if hasattr(obj, attr):
            return getattr(obj, attr)
        if isinstance(obj, dict):
            return obj.get(attr, default)
        return default

    def extract_email_from_string(self, from_string):
        """Extract email from format like 'Name <email@domain.com>' or just 'email@domain.com'"""
        if not from_string:
            return None

        # Try to extract from format: Name <email@domain.com>
        import re
        match = re.search(r'<([^>]+)>', from_string)
        if match:
            return match.group(1)

        # If no angle brackets, assume it's just the email
        if '@' in from_string:
            return from_string.strip()

        return None

    def should_auto_reply(self, message):
        """Determine if we should auto-reply to this message"""
        from_field = self._get_attr(message, 'from_', '') or self._get_attr(message, 'from', '')

        # Handle both string and list formats
        if isinstance(from_field, list) and len(from_field) > 0:
            from_field = from_field[0]

        sender_email = self.extract_email_from_string(from_field)
        if not sender_email:
            return False, "Cannot parse sender"

        sender_email = sender_email.lower()

        # Don't reply to our own emails
        if self.inbox_id.lower() in sender_email:
            return False, "Own email"

        # Don't reply to no-reply addresses
        if 'noreply' in sender_email or 'no-reply' in sender_email:
            return False, "No-reply address"

        # Don't reply to newsletters/marketing (optional)
        subject = self._get_attr(message, 'subject', '').lower()
        if any(word in subject for word in ['unsubscribe', 'newsletter', 'marketing']):
            return False, "Newsletter/marketing"

        return True, sender_email

    def send_reply(self, original_message, custom_text=None):
        """Send auto-reply to a message"""
        from_field = self._get_attr(original_message, 'from_', '') or self._get_attr(original_message, 'from', '')

        # Handle both string and list formats
        if isinstance(from_field, list) and len(from_field) > 0:
            from_field = from_field[0]

        to_email = self.extract_email_from_string(from_field)
        if not to_email:
            print(f"Cannot extract email from: {from_field}")
            return False

        subject = self._get_attr(original_message, 'subject', '')

        # Prepare reply text
        if custom_text:
            reply_text = custom_text
        else:
            reply_text = self.reply_template.format(subject=subject)

        # Add reference to original message
        reply_subject = f"Re: {subject}" if not subject.startswith('Re:') else subject

        try:
            response = self.client.inboxes.messages.send(
                inbox_id=self.inbox_id,
                to=[to_email],
                subject=reply_subject,
                text=reply_text
            )
            return True
        except Exception as e:
            print(f"Failed to send reply: {e}")
            return False

    def process_messages(self):
        """Check for new messages and send auto-replies"""
        try:
            messages = self.client.inboxes.messages.list(
                inbox_id=self.inbox_id,
                limit=20
            )

            replied_count = 0
            for message in messages.messages:
                message_id = self._get_attr(message, 'message_id')

                # Skip already replied messages
                if message_id in self.replied_ids:
                    continue

                # Check if we should reply
                should_reply, result = self.should_auto_reply(message)

                if should_reply:
                    # Send auto-reply
                    if self.send_reply(message):
                        print(f"✅ Auto-replied to: {result}")
                        self.replied_ids.add(message_id)
                        replied_count += 1
                    else:
                        print(f"❌ Failed to reply to: {message_id}")
                else:
                    print(f"⏭️  Skipped ({result}): {self._get_attr(message, 'message_id', 'N/A')}")
                    self.replied_ids.add(message_id)  # Mark as processed even if skipped

            if replied_count > 0:
                self._save_replied_ids()
                print(f"📬 Sent {replied_count} auto-reply(s)")
            else:
                print("📭 No new messages to reply to")

            return replied_count

        except Exception as e:
            print(f"❌ Error processing messages: {e}")
            return 0

    def run_daemon(self, interval=60):
        """Run as daemon, checking for new emails periodically"""
        print(f"🤖 Auto-reply bot daemon started")
        print(f"   Inbox: {self.inbox_id}")
        print(f"   Check interval: {interval} seconds")
        print(f"   Press Ctrl+C to stop\n")

        try:
            while True:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print(f"[{timestamp}] Checking for new emails...")
                self.process_messages()
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n👋 Daemon stopped")


def main():
    parser = argparse.ArgumentParser(description='Auto-reply bot for AgentMail')
    parser.add_argument('--inbox', required=True, help='AgentMail inbox address')
    parser.add_argument('--template', help='Custom reply template (use {subject} for subject placeholder)')
    parser.add_argument('--daemon', type=int, metavar='SECONDS', help='Run as daemon, check every N seconds')
    parser.add_argument('--once', action='store_true', help='Run once and exit (default)')

    args = parser.parse_args()

    # Get API key
    api_key = os.getenv('AGENTMAIL_API_KEY')
    if not api_key:
        print("Error: AGENTMAIL_API_KEY environment variable not set")
        sys.exit(1)

    # Create bot
    bot = AutoReplyBot(api_key, args.inbox, reply_template=args.template)

    # Run
    if args.daemon:
        bot.run_daemon(interval=args.daemon)
    else:
        bot.process_messages()


if __name__ == '__main__':
    main()
