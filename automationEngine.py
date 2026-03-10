import os
import base64
import requests
from flask import Flask, jsonify
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
from slack_sdk.webhook import WebhookClient

# --- CONFIG ---
PRESENTATION_ID = os.environ.get("PRESENTATION_ID", "YOUR_SLIDES_ID")
SLACK_WEBHOOK = os.environ.get("SLACK_WEBHOOK", "YOUR_SLACK_WEBHOOK")
TEAMS_WEBHOOK = os.environ.get("TEAMS_WEBHOOK", "YOUR_TEAMS_WEBHOOK")

creds = Credentials.from_service_account_file(
    "credentials.json",
    scopes=[
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/presentations"
    ]
)
slides = build("slides", "v1", credentials=creds)

# --- TABLE RENDERING ---
def insert_table(slide_id, object_id, columns, rows, x=60, y=140, w=600, h=200):
    req = {
        "createTable": {
            "objectId": object_id,
            "elementProperties": {
                "pageObjectId": slide_id,
                "size": {
                    "width": {"magnitude": w, "unit": "PT"},
                    "height": {"magnitude": h, "unit": "PT"}
                },
                "transform": {
                    "scaleX": 1,
                    "scaleY": 1,
                    "translateX": x,
                    "translateY": y,
                    "unit": "PT"
                }
            },
            "rows": len(rows) + 1,
            "columns": len(columns)
        }
    }
    slides.presentations().batchUpdate(
        presentationId=PRESENTATION_ID,
        body={"requests": [req]}
    ).execute()
    # Insert header
    for col_idx, col in enumerate(columns):
        slides.presentations().batchUpdate(
            presentationId=PRESENTATION_ID,
            body={"requests": [{
                "insertText": {
                    "objectId": object_id,
                    "cellLocation": {"rowIndex": 0, "columnIndex": col_idx},
                    "text": col
                }
            }]}
        ).execute()
    # Insert rows
    for row_idx, row in enumerate(rows):
        for col_idx, cell in enumerate(row):
            slides.presentations().batchUpdate(
                presentationId=PRESENTATION_ID,
                body={"requests": [{
                    "insertText": {
                        "objectId": object_id,
                        "cellLocation": {"rowIndex": row_idx + 1, "columnIndex": col_idx},
                        "text": str(cell)
                    }
                }]}
            ).execute()

# --- RED BUTTON LOGIC ---
def classify_severity(task):
    p = task["breach_probability"]
    t = task["time_to_sla_minutes"]
    if p >= 0.9 and t <= 30: return "Critical"
    if p >= 0.8 and t <= 60: return "High"
    if p >= 0.6: return "Medium"
    return "Low"

def build_red_button_events(tasks):
    return [
        [
            f"RB-{t['task_id']}",
            "Imminent SLA breach",
            classify_severity(t),
            t["owner"],
            "Open"
        ]
        for t in tasks if classify_severity(t) in ("Critical","High")
    ]

# --- CHART RENDERING (Chart.js via Node) ---
def render_chart_via_node(chart_config):
    resp = requests.post("http://chart-service/render", json={"config": chart_config})
    resp.raise_for_status()
    png_b64 = resp.json()["image_base64"]
    return f"data:image/png;base64,{png_b64}"

def insert_chart_image(slide_id, object_id, image_url, x=60, y=180):
    req = {
        "createImage": {
            "objectId": object_id,
            "url": image_url,
            "elementProperties": {
                "pageObjectId": slide_id,
                "transform": {
                    "scaleX": 1,
                    "scaleY": 1,
                    "translateX": x,
                    "translateY": y,
                    "unit": "PT",
                },
            },
        }
    }
    slides.presentations().batchUpdate(
        presentationId=PRESENTATION_ID,
        body={"requests": [req]}
    ).execute()

# --- NOTIFICATIONS ---
def notify_slack(url):
    webhook = WebhookClient(SLACK_WEBHOOK)
    webhook.send(text=f"📊 Mission Control deck generated\n{url}")

def notify_teams(url):
    payload = {
        "@type": "MessageCard",
        "@context": "https://schema.org/extensions",
        "summary": "Mission Control deck generated",
        "themeColor": "0078D4",
        "title": "Mission Control deck generated",
        "text": f"[Open in Google Slides]({url})"
    }
    requests.post(TEAMS_WEBHOOK, json=payload)

# --- FLASK APP FOR CLOUD RUN ---
app = Flask(__name__)

@app.post("/run-mission-control")
def run_mission_control():
    # Example data context
    tasks = [
        {"task_id": "T-001", "breach_probability": 0.95, "time_to_sla_minutes": 20, "owner": "alice@team"},
        {"task_id": "T-002", "breach_probability": 0.85, "time_to_sla_minutes": 50, "owner": "bob@team"},
        {"task_id": "T-003", "breach_probability": 0.5, "time_to_sla_minutes": 120, "owner": "carol@team"},
    ]
    red_button_rows = build_red_button_events(tasks)
    # Create slide and insert table
    slide_id = "slide_rb_summary"
    object_id = "rb_summary_table"
    columns = ["Escalation ID","Reason","Severity","Owner","Status"]
    insert_table(slide_id, object_id, columns, red_button_rows)
    # Insert chart example
    chart_config = {"type": "bar", "data": {"labels": ["A","B"], "datasets": [{"label": "Demo", "data": [1,2]}]}}
    image_url = render_chart_via_node(chart_config)
    insert_chart_image(slide_id, "rb_chart_img", image_url)
    url = f"https://docs.google.com/presentation/d/{PRESENTATION_ID}/edit"
    notify_slack(url)
    notify_teams(url)
    return jsonify({"status": "ok", "slides_url": url})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
