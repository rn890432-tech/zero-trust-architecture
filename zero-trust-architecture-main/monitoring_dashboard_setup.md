# 📊 Metric Definitions

Chart Rendering Latency

metric:
  name: custom.googleapis.com/chart_rendering_latency
  type: distribution
  labels:
    - chart_type
    - service
  unit: "ms"
  description: "Latency of chart rendering requests"

Alert Delivery Count

metric:
  name: custom.googleapis.com/alert_delivery_count
  type: counter
  labels:
    - alert_type
    - channel
  unit: "1"
  description: "Number of alerts delivered by type and channel"

---

# 🔔 Alerting Policies

SLA Compliance Alert

condition:
  displayName: "SLA Compliance < 90%"
  conditionThreshold:
    filter: 'metric.type="custom.googleapis.com/sla_compliance"'
    comparison: COMPARISON_LT
    thresholdValue: 0.9
    duration: "300s"
notificationChannels:
  - slack-channel-id
  - teams-channel-id

Red Button Escalation Alert

condition:
  displayName: "Red Button Escalations > 5"
  conditionThreshold:
    filter: 'metric.type="custom.googleapis.com/red_button_escalations"'
    comparison: COMPARISON_GT
    thresholdValue: 5
    duration: "300s"
notificationChannels:
  - slack-channel-id
  - teams-channel-id

Forecasted Breaches Alert

condition:
  displayName: "Forecasted Breaches > 10"
  conditionThreshold:
    filter: 'metric.type="custom.googleapis.com/forecasted_breaches"'
    comparison: COMPARISON_GT
    thresholdValue: 10
    duration: "300s"
notificationChannels:
  - slack-channel-id
  - teams-channel-id

---

# 🔔 Cloud Monitoring → Slack/Teams Notifications

## Step 1 — Create Notification Channels

Slack:
1. Go to Cloud Monitoring → Notification Channels.
2. Add a new Slack channel.
3. Paste in your Slack webhook URL (from your workspace’s app integration).
4. Save.

Teams:
1. In Microsoft Teams, create an Incoming Webhook connector for the channel you want.
2. Copy the webhook URL.
3. In Cloud Monitoring → Notification Channels, add a new “Webhook” channel.
4. Paste the Teams webhook URL.

## Step 2 — Attach Channels to Alerting Policies

When you define your alerting policies (SLA < 90%, Red Button > 5, Forecasted Breaches > 10), add:

notificationChannels:
  - projects/<PROJECT_ID>/notificationChannels/<SLACK_CHANNEL_ID>
  - projects/<PROJECT_ID>/notificationChannels/<TEAMS_CHANNEL_ID>

Now, whenever a condition is met, Cloud Monitoring automatically posts into Slack/Teams.

---

# 📈 Dashboard Widget Examples

Line Chart — Rendering Latency

widget:
  title: "Chart Rendering Latency"
  type: line_chart
  metric: custom.googleapis.com/chart_rendering_latency
  group_by: chart_type
  x_axis: time
  y_axis: latency_ms

Stacked Bar Chart — Alert Delivery Count

widget:
  title: "Alert Delivery Count by Type"
  type: stacked_bar_chart
  metric: custom.googleapis.com/alert_delivery_count
  group_by: alert_type
  x_axis: time
  y_axis: count

---

# 📈 Expanded Dashboard Widgets

SLA Compliance Trend

widget:
  title: "SLA Compliance Trend"
  type: line_chart
  metric: custom.googleapis.com/sla_compliance
  x_axis: time
  y_axis: compliance_percentage

Red Button Escalation Count

widget:
  title: "Red Button Escalations"
  type: bar_chart
  metric: custom.googleapis.com/red_button_escalations
  group_by: severity
  x_axis: time
  y_axis: count

Forecasted Breaches

widget:
  title: "Forecasted Breaches"
  type: line_chart
  metric: custom.googleapis.com/forecasted_breaches
  x_axis: time
  y_axis: breach_count

---

# 📈 Synthetic Test Metrics

Before live data flows in, you can inject synthetic values to validate dashboards and alerts.

Example Python:

def push_test_metrics():
    # Simulate SLA compliance drop
    record_latency("summary_chart", "mission_control", 2500)  # 2.5s latency
    record_alert_delivery("RedButton", "Slack")
    record_alert_delivery("RedButton", "Teams")

    # Simulate SLA compliance metric
    from google.cloud import monitoring_v3
    import time
    client = monitoring_v3.MetricServiceClient()
    project_name = f"projects/{PROJECT_ID}"
    series = monitoring_v3.TimeSeries()
    series.metric.type = "custom.googleapis.com/sla_compliance"
    series.resource.type = "global"
    point = monitoring_v3.Point()
    point.value.double_value = 0.85  # 85% compliance
    point.interval.end_time.seconds = int(time.time())
    series.points.append(point)
    client.create_time_series(name=project_name, time_series=[series])

Run this once — dashboards will show data, and alerts will fire into Slack/Teams so you can confirm end‑to‑end wiring.

---

# 🔄 Automated Recovery Actions

Instead of just alerting, you can trigger self‑healing scripts when metrics cross thresholds.

Example: restart a service if latency spikes.

```python
def auto_recover(latency_ms):
    if latency_ms > 3000:  # 3 seconds threshold
        log_event("auto_recovery_triggered", {"latency": latency_ms})
        # Example: restart container or scale service
        import subprocess
        subprocess.run(["gcloud","run","services","update","mission-control","--cpu=2"])
        alert_slack("🚑 Auto-recovery: scaled Mission Control service due to latency spike")
```

This way, the system doesn’t just complain — it fixes itself.

---

# 📅 On‑Call Schedule Integration

Tie alerts to whoever is on duty using Google Calendar or Outlook.

Google Calendar Example:
- Create a shared “On‑Call” calendar.
- Each week, assign Ops engineers as all‑day events with their email.

Python code to fetch current on‑call:

```python
from googleapiclient.discovery import build
from google.oauth2 import service_account
import datetime

def get_oncall_person():
    creds = service_account.Credentials.from_service_account_file("creds.json")
    service = build("calendar","v3",credentials=creds)
    now = datetime.datetime.utcnow().isoformat() + "Z"
    events = service.events().list(calendarId="oncall@example.com",
                                   timeMin=now,
                                   maxResults=1,
                                   singleEvents=True,
                                   orderBy="startTime").execute()
    if events["items"]:
        return events["items"][0]["attendees"][0]["email"]
    return None
```

Then route alerts to that person’s Slack/Teams DM automatically.

---

# 📒 Runbook Automation Flow

1. Alert fires (SLA drop, Red Button escalation, latency spike).
2. Automation script runs:
   • Logs the incident in Cloud Logging.
   • Creates a ticket in Jira/ServiceNow.
   • Notifies stakeholders in Slack/Teams.
   • Optionally triggers recovery actions (restart/scale service).

---

# 🧩 Example Python Runbook Script

```python
import requests, datetime, json

def runbook_trigger(alert_type, severity, details):
    timestamp = datetime.datetime.utcnow().isoformat()

    # 1. Log incident
    incident = {
        "timestamp": timestamp,
        "alert_type": alert_type,
        "severity": severity,
        "details": details
    }
    print(json.dumps(incident))  # goes to Cloud Logging

    # 2. Create ticket (Jira example)
    jira_url = "https://yourcompany.atlassian.net/rest/api/2/issue"
    jira_auth = ("jira_user","jira_token")
    payload = {
        "fields": {
            "project": {"key": "OPS"},
            "summary": f"{severity} Alert: {alert_type}",
            "description": json.dumps(details),
            "issuetype": {"name": "Incident"}
        }
    }
    requests.post(jira_url, json=payload, auth=jira_auth)

    # 3. Notify stakeholders
    if severity == "Critical":
        alert_slack(f"🚨 Critical {alert_type} — ticket created in Jira")
    elif severity == "High":
        alert_teams(f"⚠️ High {alert_type} — ticket created in Jira")
    else:
        alert_slack(f"Info {alert_type} logged")
```

---

# 📅 Rotating On‑Call Schedules

You can generate weekly rosters automatically:

• Google Calendar API: script inserts all‑day events for each engineer.
• Outlook API: same idea, recurring events for on‑call duty.
• Alerts query the calendar to see who’s on duty and route accordingly.

Example roster generator:

```python
def generate_oncall_roster(team_emails):
    # Rotate weekly
    import datetime
    week_number = datetime.date.today().isocalendar()[1]
    oncall_index = week_number % len(team_emails)
    return team_emails[oncall_index]
```

This ensures every week a different engineer is automatically assigned.

---

# 📝 Integrating Ticket IDs into the Deck

When your runbook creates a Jira/ServiceNow ticket, capture the ticket ID and feed it into your weekly slides.

Example:

```python
def add_incident_table(slide_id, incidents):
    insert_table(
        slide_id=slide_id,
        object_id="incident_summary_table",
        columns=["Ticket ID","Alert Type","Severity","Owner","Status"],
        rows=[
            [i["ticket_id"], i["alert_type"], i["severity"], i["owner"], i["status"]]
            for i in incidents
        ]
    )
```

Now leadership sees open incidents with ticket IDs right in the weekly deck.

---

# 📧 Stakeholder Email Summaries

After each incident, send a concise summary email to stakeholders.

Example:

```python
def send_incident_summary(incident):
    subject = f"Incident Report: {incident['ticket_id']} ({incident['severity']})"
    body = f"""
    Incident {incident['ticket_id']} was triggered at {incident['timestamp']}.

    Type: {incident['alert_type']}
    Severity: {incident['severity']}
    Owner: {incident['owner']}
    Status: {incident['status']}

    Details:
    {incident['details']}

    The incident has been logged and a ticket created in Jira/ServiceNow.
    """
    alert_slack(f"📧 Stakeholder summary sent for {incident['ticket_id']}")
    alert_teams(f"📧 Stakeholder summary sent for {incident['ticket_id']}")
    # Also send via email (SMTP or Gmail API)
```

This ensures stakeholders get real‑time email reports whenever an incident occurs.

---

# 📊 Weekly Executive Summary Slide

At the end of each deck run, generate a slide that aggregates the week’s key metrics:

```python
def add_executive_summary_slide(presentation_id, metrics, incidents):
    slide_id = create_slide(presentation_id, "Executive Summary")
    insert_table(
        slide_id=slide_id,
        object_id="exec_summary_table",
        columns=["Metric","Value"],
        rows=[
            ["SLA Compliance", f"{metrics['sla_compliance']:.0%}"],
            ["Red Button Escalations", str(metrics['red_button_count'])],
            ["Forecasted Breaches", str(metrics['forecasted_breaches'])],
            ["Incidents Opened", str(len(incidents))],
            ["Recovery Actions", str(metrics['auto_recoveries'])]
        ]
    )
    insert_text(slide_id, "summary_text_box",
                "This week’s Mission Control performance overview.")
```

Leadership sees SLA %, escalations, breaches, incidents, and recovery actions in one glance.

---

# 📧 Weekly Digest Email

Batch stakeholder summaries into a single digest, sent via Cloud Scheduler every Monday after deck generation.

```python
def send_weekly_digest(metrics, incidents):
    subject = "Mission Control Weekly Digest"
    body = f"""
    Mission Control Weekly Summary

    SLA Compliance: {metrics['sla_compliance']:.0%}
    Red Button Escalations: {metrics['red_button_count']}
    Forecasted Breaches: {metrics['forecasted_breaches']}
    Incidents Opened: {len(incidents)}
    Recovery Actions: {metrics['auto_recoveries']}

    Incident Details:
    {chr(10).join([f"{i['ticket_id']} - {i['alert_type']} ({i['severity']})" for i in incidents])}

    This digest is auto‑generated by Mission Control.
    """
    # Send via Gmail/Outlook API
    send_email(subject, body, recipients=["execs@example.com"])
```

Cloud Scheduler triggers this digest job weekly, ensuring executives get a single, polished report.

---

# 🔮 Predictive Analytics (Forecast SLA Compliance)

Use historical SLA data to forecast next month’s compliance. A simple approach is linear regression; more advanced would be ARIMA or Prophet.

Example (Python + scikit‑learn):

```python
import numpy as np
from sklearn.linear_model import LinearRegression

def forecast_sla(sla_history):
    # sla_history = [{"month":1,"sla_compliance":0.92}, {"month":2,"sla_compliance":0.89}, ...]
    X = np.array([h["month"] for h in sla_history]).reshape(-1,1)
    y = np.array([h["sla_compliance"] for h in sla_history])
    model = LinearRegression().fit(X,y)
    next_month = np.array([[sla_history[-1]["month"]+1]])
    forecast = model.predict(next_month)[0]
    return forecast
```

Add a slide:

```python
def add_forecast_slide(presentation_id, forecast_value):
    slide_id = create_slide(presentation_id, "Forecast SLA Compliance")
    insert_text(slide_id, "forecast_text_box",
                f"Projected SLA compliance next month: {forecast_value:.0%}")
```

---

# 🔎 Anomaly Detection

Instead of just forecasting, add anomaly detection to flag unusual drops or spikes.

Example (Python + SciPy):

```python
import numpy as np
from scipy import stats

def detect_anomalies(values):
    z_scores = np.abs(stats.zscore(values))
    anomalies = [i for i, z in enumerate(z_scores) if z > 2]  # threshold
    return anomalies
```

Usage:

```python
sla_values = [0.95, 0.93, 0.92, 0.70, 0.91]  # sudden drop at 0.70
anomalies = detect_anomalies(sla_values)
if anomalies:
    alert_slack(f"🚨 SLA anomaly detected at index {anomalies}")
```

This flags unusual SLA drops or escalation spikes automatically.

---

# 📚 Automated Archiving

Every weekly deck and digest should be versioned and searchable in Confluence/SharePoint.

Confluence Archive:

```python
def archive_weekly_report(deck_url, digest_text, week_number):
    page_title = f"Mission Control Weekly Report - Week {week_number}"
    payload = {
        "title": page_title,
        "type": "page",
        "space": {"key": "OPS"},
        "body": {
            "storage": {
                "value": f"<p>Deck: <a href='{deck_url}'>{deck_url}</a></p><p>{digest_text}</p>",
                "representation": "storage"
            }
        }
    }
    import requests
    requests.post("https://yourcompany.atlassian.net/wiki/rest/api/content",
                  json=payload, headers={"Authorization":"Bearer <token>"})
```

SharePoint Archive:

Use Microsoft Graph API to upload each digest as a document:

• File name: MissionControl_Week_<week_number>.docx
• Stored in a leadership site library.
• Searchable by week, SLA, escalation count.

---

# 🔎 Natural‑Language Search over the Archive

Instead of scrolling through Confluence/SharePoint manually, leadership can type queries like “show me last month’s SLA anomalies”.

Approach:
1. Index all weekly digests into a searchable store (e.g., ElasticSearch, Azure Cognitive Search, or Google Cloud Search).
2. Add metadata: week number, SLA %, escalation counts, incident categories.
3. Enable natural‑language queries: use embeddings or keyword search to match queries to archived reports.

Example (pseudo‑code with ElasticSearch):

```python
def search_archive(query):
    response = es.search(
        index="mission-control-archive",
        body={"query": {"match": {"content": query}}}
    )
    return [hit["_source"] for hit in response["hits"]["hits"]]
```

Now leadership can ask in plain English, and the system returns the relevant weekly digest or deck.

---

# 💬 Natural‑Language Queries in Slack/Teams

Wire your archive search into chat so executives can type questions like “show me last month’s SLA anomalies”.

Slack Bot Example (Python + Slack API):

```python
@slack_event("message")
def handle_query(event):
    query = event["text"]
    results = search_archive(query)  # from ElasticSearch/Cloud Search
    response = format_results(results)
    slack_client.chat_postMessage(channel=event["channel"], text=response)
```

Teams Bot Example (Python + Bot Framework):

```python
async def on_message_activity(turn_context):
    query = turn_context.activity.text
    results = search_archive(query)
    response = format_results(results)
    await turn_context.send_activity(response)
```

Now leadership can ask questions in chat and get direct answers from the archive.

---

# ⚙️ Automated Playbooks for Recovery

When anomaly detection fires, trigger a playbook script that executes the recommended fix.

Example: SLA anomaly → auto‑scale service, log incident, notify stakeholders.

```python
def sla_playbook(anomaly_value):
    # 1. Scale service
    import subprocess
    subprocess.run(["gcloud","run","services","update","mission-control","--cpu=2"])
    # 2. Log incident
    log_event("sla_playbook_triggered", {"sla_value": anomaly_value})
    # 3. Notify stakeholders
    alert_slack(f"🚑 SLA anomaly {anomaly_value:.0%}. Auto-scaled service.")
    alert_teams(f"🚑 SLA anomaly {anomaly_value:.0%}. Auto-scaled service.")
    # 4. Create ticket
    create_jira_ticket("SLA anomaly auto-recovery", "Critical", anomaly_value)
```

Different playbooks can handle latency spikes, escalation surges, or forecasted breaches — each with automated fixes.

---

# 🚀 Summary

• Automated recovery: services scale or restart themselves when latency spikes.
• On‑call integration: alerts routed to whoever is scheduled in Google Calendar/Outlook.
• Escalation routing: Critical → Ops, High → Managers, Info → General.
• Synthetic load tests: validate recovery + routing before production.
• Runbook automation: alerts → logs → tickets → notifications → recovery.
• Rotating on‑call schedules: weekly roster auto‑generated, alerts routed to whoever is on duty.
• Incident lifecycle: fully automated from detection to resolution.
• Deck integration: ticket IDs and incident details visible in weekly slides.
• Stakeholder summaries: automatic emails after each incident.
• Runbook automation: alerts → tickets → notifications → recovery → reporting.
• On‑call aware routing: alerts go to the right person at the right time.
• Executive summary slide: one‑page snapshot in the deck.
• Weekly digest email: batched incident + metric summary for stakeholders.
• Automation: Scheduler ensures delivery without manual effort.
• Full lifecycle: alerts → tickets → recovery → reporting → executive visibility.
• Predictive analytics: SLA compliance forecasted for next month.
• Permanent archive: weekly digests stored in Confluence/SharePoint for leadership reference.
• Executive visibility: trends, forecasts, and historical records all in one place.
• Anomaly detection: automatic flagging of unusual SLA drops or escalation spikes.
• Automated archiving: every weekly deck + digest versioned in Confluence/SharePoint.
• Searchable history: leadership can query past reports by week, incident, or metric.
• Predictive + anomaly‑aware: Mission Control doesn’t just report — it anticipates and explains.
