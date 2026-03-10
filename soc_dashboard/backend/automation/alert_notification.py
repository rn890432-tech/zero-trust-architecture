import requests
import os

def send_email_alert(subject, message):
    # Placeholder: Integrate with real email provider
    print(f"Email sent: {subject} - {message}")

def send_slack_alert(message):
    slack_webhook = os.getenv('SLACK_WEBHOOK_URL', '')
    if slack_webhook:
        requests.post(slack_webhook, json={"text": message})
        print(f"Slack alert sent: {message}")
    else:
        print("Slack webhook not configured.")

def send_webhook_alert(payload):
    webhook_url = os.getenv('ALERT_WEBHOOK_URL', '')
    if webhook_url:
        requests.post(webhook_url, json=payload)
        print(f"Webhook alert sent: {payload}")
    else:
        print("Webhook URL not configured.")
