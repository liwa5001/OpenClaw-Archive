#!/usr/bin/env python3
"""
Check AgentMail inbox for messages

Usage:
    # List recent messages
    python check_inbox.py --inbox "myagent@agentmail.to"

    # Get specific message
    python check_inbox.py --inbox "myagent@agentmail.to" --message "msg_123abc"

    # List threads
    python check_inbox.py --inbox "myagent@agentmail.to" --threads

    # Monitor for new messages (poll every N seconds)
    python check_inbox.py --inbox "myagent@agentmail.to" --monitor 30

Environment:
    AGENTMAIL_API_KEY: Your AgentMail API key
"""

import argparse
import os
import sys
import time
from datetime import datetime

try:
    from agentmail import AgentMail
except ImportError:
    print("Error: agentmail package not found. Install with: pip install agentmail")
    sys.exit(1)

def format_timestamp(iso_string):
    """Format ISO timestamp for display"""
    try:
        dt = datetime.fromisoformat(iso_string.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        return iso_string

def get_attr(obj, attr, default=None):
    """Safely get attribute from object or dict"""
    if hasattr(obj, attr):
        return getattr(obj, attr)
    if isinstance(obj, dict):
        return obj.get(attr, default)
    return default

def print_message_summary(message):
    """Print a summary of a message"""
    # Handle both object and dict formats
    from_list = get_attr(message, 'from_', []) or get_attr(message, 'from', [])
    if from_list and len(from_list) > 0:
        from_addr = get_attr(from_list[0], 'email', 'Unknown')
        from_name = get_attr(from_list[0], 'name', '')
    else:
        from_addr = 'Unknown'
        from_name = ''

    subject = get_attr(message, 'subject', '(no subject)')
    timestamp = format_timestamp(get_attr(message, 'timestamp', ''))
    preview_text = get_attr(message, 'preview', '') or get_attr(message, 'text', '')
    preview = preview_text[:100] if preview_text else ''
    message_id = get_attr(message, 'message_id', 'N/A')

    print(f"📧 {message_id}")
    print(f"   From: {from_name} <{from_addr}>" if from_name else f"   From: {from_addr}")
    print(f"   Subject: {subject}")
    print(f"   Time: {timestamp}")
    if preview:
        print(f"   Preview: {preview}{'...' if len(preview) == 100 else ''}")
    print()

def print_thread_summary(thread):
    """Print a summary of a thread"""
    subject = get_attr(thread, 'subject', '(no subject)')
    participants = get_attr(thread, 'participants', [])
    participants_str = ', '.join(participants) if participants else 'N/A'
    count = get_attr(thread, 'message_count', 0)
    timestamp = format_timestamp(get_attr(thread, 'last_message_at', ''))
    thread_id = get_attr(thread, 'thread_id', 'N/A')

    print(f"🧵 {thread_id}")
    print(f"   Subject: {subject}")
    print(f"   Participants: {participants_str}")
    print(f"   Messages: {count}")
    print(f"   Last: {timestamp}")
    print()

def main():
    parser = argparse.ArgumentParser(description='Check AgentMail inbox')
    parser.add_argument('--inbox', required=True, help='Inbox email address')
    parser.add_argument('--message', help='Get specific message by ID')
    parser.add_argument('--threads', action='store_true', help='List threads instead of messages')
    parser.add_argument('--monitor', type=int, metavar='SECONDS', help='Monitor for new messages (poll interval)')
    parser.add_argument('--limit', type=int, default=10, help='Number of items to fetch (default: 10)')

    args = parser.parse_args()

    # Get API key
    api_key = os.getenv('AGENTMAIL_API_KEY')
    if not api_key:
        print("Error: AGENTMAIL_API_KEY environment variable not set")
        sys.exit(1)

    # Initialize client
    client = AgentMail(api_key=api_key)

    if args.monitor:
        print(f"🔍 Monitoring {args.inbox} (checking every {args.monitor} seconds)")
        print("Press Ctrl+C to stop\n")

        last_message_ids = set()

        try:
            while True:
                try:
                    messages = client.inboxes.messages.list(
                        inbox_id=args.inbox,
                        limit=args.limit
                    )

                    new_messages = []
                    current_message_ids = set()

                    for message in messages.messages:
                        msg_id = get_attr(message, 'message_id')
                        current_message_ids.add(msg_id)

                        if msg_id not in last_message_ids:
                            new_messages.append(message)

                    if new_messages:
                        print(f"🆕 Found {len(new_messages)} new message(s):")
                        for message in new_messages:
                            print_message_summary(message)

                    last_message_ids = current_message_ids

                except Exception as e:
                    print(f"❌ Error checking inbox: {e}")

                time.sleep(args.monitor)

        except KeyboardInterrupt:
            print("\n👋 Monitoring stopped")
            return

    elif args.message:
        # Get specific message
        try:
            message = client.inboxes.messages.get(
                inbox_id=args.inbox,
                message_id=args.message
            )

            print(f"📧 Message Details:")
            print(f"   ID: {get_attr(message, 'message_id')}")
            print(f"   Thread: {get_attr(message, 'thread_id')}")

            from_list = get_attr(message, 'from_', []) or get_attr(message, 'from', [])
            if from_list and len(from_list) > 0:
                from_addr = get_attr(from_list[0], 'email', 'Unknown')
                from_name = get_attr(from_list[0], 'name', '')
            else:
                from_addr = 'Unknown'
                from_name = ''

            print(f"   From: {from_name} <{from_addr}>" if from_name else f"   From: {from_addr}")

            to_list = get_attr(message, 'to', [])
            to_addrs = ', '.join([get_attr(addr, 'email', '') for addr in to_list])
            print(f"   To: {to_addrs}")

            print(f"   Subject: {get_attr(message, 'subject', '(no subject)')}")
            print(f"   Time: {format_timestamp(get_attr(message, 'timestamp', ''))}")

            labels = get_attr(message, 'labels', [])
            if labels:
                print(f"   Labels: {', '.join(labels)}")

            print("\n📝 Content:")
            text_content = get_attr(message, 'text', '')
            html_content = get_attr(message, 'html', '')
            if text_content:
                print(text_content)
            elif html_content:
                print("(HTML content - use API to get full HTML)")
            else:
                print("(No text content)")

            attachments = get_attr(message, 'attachments', [])
            if attachments:
                print(f"\n📎 Attachments ({len(attachments)}):")
                for att in attachments:
                    filename = get_attr(att, 'filename', 'unnamed')
                    content_type = get_attr(att, 'content_type', 'unknown type')
                    print(f"   • {filename} ({content_type})")

        except Exception as e:
            print(f"❌ Error getting message: {e}")
            sys.exit(1)

    elif args.threads:
        # List threads
        try:
            threads = client.inboxes.threads.list(
                inbox_id=args.inbox,
                limit=args.limit
            )

            if not threads.threads:
                print(f"📭 No threads found in {args.inbox}")
                return

            print(f"🧵 Threads in {args.inbox} (showing {len(threads.threads)}):\n")
            for thread in threads.threads:
                print_thread_summary(thread)

        except Exception as e:
            print(f"❌ Error listing threads: {e}")
            sys.exit(1)

    else:
        # List recent messages
        try:
            messages = client.inboxes.messages.list(
                inbox_id=args.inbox,
                limit=args.limit
            )

            if not messages.messages:
                print(f"📭 No messages found in {args.inbox}")
                return

            print(f"📧 Messages in {args.inbox} (showing {len(messages.messages)}):\n")
            for message in messages.messages:
                print_message_summary(message)

        except Exception as e:
            print(f"❌ Error listing messages: {e}")
            sys.exit(1)

if __name__ == '__main__':
    main()
