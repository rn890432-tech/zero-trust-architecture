#!/bin/bash
# alert_hooks.sh - Custom alert actions for lockout events
# Usage: ./alert_hooks.sh "username" "event"

USER="$1"
EVENT="$2"
EMAIL="jasonnorman66994@gmail.com"
PHONE="+1234567890"

echo "Security alert: $EVENT for $USER at $(date)" | mail -s "Zero Trust Security Alert" "$EMAIL"

curl -X POST https://api.twilio.com/2010-04-01/Accounts/ACc9850e0b35602ab0e4beefbed20e137d/Messages.json \
	--data-urlencode "To=+17867812573" \
	--data-urlencode "From=+18446300376" \
	--data-urlencode "Body=Security alert: $EVENT for $USER at $(date)" \
	-u ACc9850e0b35602ab0e4beefbed20e137d:1596fcdb438a320ca315489831ec83fb

# You can add more integrations here (Slack, Teams, etc.)
