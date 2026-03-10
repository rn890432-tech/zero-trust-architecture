import requests
from secret_manager_helpers import get_secret

def alert_slack(message):
    webhook = get_secret("slack-webhook")
    requests.post(webhook, json={"text": f"🚨 {message}"})

def alert_teams(message):
    webhook = get_secret("teams-webhook")
    payload = {
        "@type": "MessageCard",
        "@context": "https://schema.org/extensions",
        "summary": "Mission Control Alert",
        "themeColor": "FF0000",
        "title": "🚨 Mission Control Alert",
        "text": message
    }
    requests.post(webhook, json=payload)

def check_alerts(data):
    if data["metrics"]["sla_compliance"] < 0.9:
        msg = f"SLA compliance dropped to {data['metrics']['sla_compliance']:.0%}"
        alert_slack(msg)
        alert_teams(msg)

def check_red_button_alerts(escalations):
    if len(escalations) > 5:
        msg = f"🚨 {len(escalations)} Red Button escalations detected this week!"
        alert_slack(msg)
        alert_teams(msg)

def check_forecast_alerts(data):
    if data["metrics"]["forecasted_breaches"] > 10:
        msg = f"⚠️ Forecast shows {data['metrics']['forecasted_breaches']} breaches next week."
        alert_slack(msg)
        alert_teams(msg)
