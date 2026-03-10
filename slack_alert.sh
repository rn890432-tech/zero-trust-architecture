#!/bin/bash
# slack_alert.sh - Send alert to Slack channel via webhook
# Usage: ./slack_alert.sh "Alert message text"

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"
MESSAGE="$1"

curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE\"}" "$SLACK_WEBHOOK_URL"
