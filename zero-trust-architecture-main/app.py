# --- Root Cause → Action Mapping ---
ROOT_CAUSE_ACTIONS = {
    'Insufficient Data': 'Improve data pipelines and validation checks',
    'Policy Misalignment': 'Review override policy documentation and clarify criteria',
    'Other': 'Investigate case manually and document findings'
}

def get_recommended_action(reason):
    return ROOT_CAUSE_ACTIONS.get(reason, ROOT_CAUSE_ACTIONS['Other'])
# --- Baseline Calculation & Anomaly Detection ---
def calculate_baseline():
    import csv, dae
    weekly_stats = {}
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status = row.get('status','')
            resolved_time = row.get('resolution_time','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    week = resolved_dt.isocalendar()[1]
                    year = resolved_dt.year
                    key = f"{year}-W{week}"
                    if key not in weekly_stats:
                        weekly_stats[key] = {'approvals':0,'rejections':0}
                    if status == 'resolved':
                        weekly_stats[key]['approvals'] += 1
                    elif status == 'rejected':
                        weekly_stats[key]['rejections'] += 1
                except Exception:
                    pass
    approvals = [v['approvals'] for v in weekly_stats.values()]
    rejections = [v['rejections'] for v in weekly_stats.values()]
    avg_approvals = sum(approvals)/len(approvals) if approvals else 0
    avg_rejections = sum(rejections)/len(rejections) if rejections else 0
    return avg_approvals, avg_rejections

def detect_anomalies():
    import csv, datetime
    avg_approvals, avg_rejections = calculate_baseline()
    now = datetime.datetime.now()
    current_week = now.isocalendar()[1]
    current_year = now.year
    current_key = f"{current_year}-W{current_week}"
    approvals = 0
    rejections = 0
    request_ids = set()
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status = row.get('status','')
            resolved_time = row.get('resolution_time','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    week = resolved_dt.isocalendar()[1]
                    year = resolved_dt.year
                    key = f"{year}-W{week}"
                    if key == current_key:
                        request_ids.add(row['request_id'])
                        if status == 'resolved':
                            approvals += 1
                        elif status == 'rejected':
                            rejections += 1
                except Exception:
                    pass
    deviation = 0
    if avg_rejections:
        deviation = (rejections - avg_rejections) / avg_rejections
    # Aggregate root causes for current week
    causes = {}
    with open('automation/retraining_override_votes.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['decision'] == 'reject' and row['request_id'] in request_ids:
                r = row.get('reason','Other') or 'Other'
                causes[r] = causes.get(r,0) + 1
    if rejections > avg_rejections * 1.5:
        send_anomaly_alert_with_causes("Rejection rate spike", rejections, avg_rejections, deviation, causes)

def send_anomaly_alert_with_causes(type, current, baseline, deviation, causes):
    import csv, datetime
    import csv, datetime
    # Join root causes with recommended actions
    action_map = {}
    with open('automation/rejection_actions.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            action_map[row['reason']] = row['recommended_action']
    causeLines = '\n'.join([f"• {reason}: {count} → Recommended: {action_map.get(reason, 'Investigate case manually and document findings')}" for reason, count in causes.items()])
    payload = {
        "channel": "#engineering-leads",
        "text": "🚨 Override Anomaly Detected",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"🚨 *{type}*\nCurrent: {current}\nBaseline Avg: {baseline:.1f}\nDeviation: {deviation*100:.1f}%\n\nRoot Causes & Recommended Actions:\n{causeLines}"
                }
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)
    # Log corrective actions and create tickets
    now = datetime.datetime.now().isoformat()
    with open('automation/corrective_actions.csv', 'a', newline='') as f:
        writer = csv.writer(f)
        for reason in causes:
            action = action_map.get(reason, 'Investigate case manually and document findings')
            writer.writerow(['', '', reason, action, 'false', ''])
            create_ticket_for_action(reason, action)

def create_ticket_for_action(reason, action):
    # Placeholder for ticketing system integration (ServiceNow, Jira, etc.)
    print(f"Ticket created for corrective action: {reason} → {action}")
# --- Automated Reminder for Pending Actions ---
    import threading, time, csv
    def job():
        while True:
            with open('automation/corrective_actions.csv') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if row['implemented'] != 'true':
                        send_action_reminder(row)
            time.sleep(86400)  # Remind daily
    threading.Thread(target=job, daemon=True).start()
# --- Dashboard Action Impact Analytics API ---
def action_impact():
    import csv, datetime
    # Calculate weeks with implemented actions vs anomaly count
    week_stats = {}
    with open('automation/corrective_actions.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['implemented'] == 'true' and row['implemented_at']:
                try:
                    dt = datetime.datetime.fromisoformat(row['implemented_at'])
                    week = dt.isocalendar()[1]
                    year = dt.year
                    key = f"{year}-W{week}"
                    week_stats[key] = week_stats.get(key, {'actions':0,'anomalies':0})
                    week_stats[key]['actions'] += 1
                except Exception:
                    pass
    # Count anomalies per week
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status = row.get('status','')
            resolved_time = row.get('resolution_time','')
            if status == 'rejected' and resolved_time:
                try:
                    dt = datetime.datetime.fromisoformat(resolved_time)
                    week = dt.isocalendar()[1]
                    year = dt.year
                    key = f"{year}-W{week}"
                    week_stats[key] = week_stats.get(key, {'actions':0,'anomalies':0})
                    week_stats[key]['anomalies'] += 1
                except Exception:
                    pass
    return jsonify(week_stats)
# --- API to mark corrective actions as implemented ---
@app.route('/api/mark_action_done', methods=['POST'])
def mark_action_done():
    import csv, tempfile, datetime
    action_id = str(request.json.get('id'))
    rows = []
    updated = False
    with open('automation/corrective_actions.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['id'] == action_id:
                row['implemented'] = 'true'
                row['implemented_at'] = datetime.datetime.now().isoformat()
                updated = True
            rows.append(row)
    with tempfile.NamedTemporaryFile('w', delete=False, newline='') as tf:
        writer = csv.DictWriter(tf, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tf.name, 'automation/corrective_actions.csv')
    return jsonify({'updated': updated})

# --- Dashboard Corrective Actions Status API ---
@app.route('/api/corrective_actions_status')
def corrective_actions_status():
    import csv
    actions = []
    with open('automation/corrective_actions.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            actions.append(row)
    return jsonify(actions)
# --- Dashboard Corrective Actions API ---
@app.route('/api/corrective_actions')
def corrective_actions():
    import csv, datetime
    now = datetime.datetime.now()
    current_week = now.isocalendar()[1]
    current_year = now.year
    current_key = f"{current_year}-W{current_week}"
    request_ids = set()
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status = row.get('status','')
            resolved_time = row.get('resolution_time','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    week = resolved_dt.isocalendar()[1]
                    year = resolved_dt.year
                    key = f"{year}-W{week}"
                    if key == current_key:
                        request_ids.add(row['request_id'])
                except Exception:
                    pass
    actions = {}
    with open('automation/retraining_override_votes.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['decision'] == 'reject' and row['request_id'] in request_ids:
                r = row.get('reason','Other') or 'Other'
                act = get_recommended_action(r)
                actions[r] = act
    return jsonify(actions)
# --- Dashboard Weekly Root Cause API ---
@app.route('/api/weekly_root_causes')
def weekly_root_causes():
    import csv, datetime
    now = datetime.datetime.now()
    current_week = now.isocalendar()[1]
    current_year = now.year
    current_key = f"{current_year}-W{current_week}"
    request_ids = set()
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status = row.get('status','')
            resolved_time = row.get('resolution_time','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    week = resolved_dt.isocalendar()[1]
                    year = resolved_dt.year
                    key = f"{year}-W{week}"
                    if key == current_key:
                        request_ids.add(row['request_id'])
                except Exception:
                    pass
    causes = {}
    with open('automation/retraining_override_votes.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['decision'] == 'reject' and row['request_id'] in request_ids:
                r = row.get('reason','Other') or 'Other'
                causes[r] = causes.get(r,0) + 1
    return jsonify(causes)

def send_anomaly_alert(type, current, baseline, deviation):
    payload = {
        "channel": "#engineering-leads",
        "text": "🚨 Override Anomaly Detected",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"🚨 *{type}*\nCurrent: {current}\nBaseline Avg: {baseline:.1f}\nDeviation: {deviation*100:.1f}%\n\nLeadership attention recommended."
                }
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)

# --- Anomaly Detection Scheduler ---
def anomaly_detection_scheduler():
    import threading, time
    def job():
        while True:
            detect_anomalies()
            time.sleep(3600)  # Check every hour
    threading.Thread(target=job, daemon=True).start()

# Start anomaly detection scheduler
anomaly_detection_scheduler()
# --- Dashboard Anomaly API ---
@app.route('/api/anomaly_indicators')
def anomaly_indicators():
    avg_approvals, avg_rejections = calculate_baseline()
    import csv, datetime
    now = datetime.datetime.now()
    current_week = now.isocalendar()[1]
    current_year = now.year
    current_key = f"{current_year}-W{current_week}"
    approvals = 0
    rejections = 0
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status = row.get('status','')
            resolved_time = row.get('resolution_time','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    week = resolved_dt.isocalendar()[1]
                    year = resolved_dt.year
                    key = f"{year}-W{week}"
                    if key == current_key:
                        if status == 'resolved':
                            approvals += 1
                        elif status == 'rejected':
                            rejections += 1
                except Exception:
                    pass
    deviation = 0
    if avg_rejections:
        deviation = (rejections - avg_rejections) / avg_rejections
    anomaly = rejections > avg_rejections * 1.5
    return jsonify({
        'current_approvals': approvals,
        'current_rejections': rejections,
        'avg_approvals': avg_approvals,
        'avg_rejections': avg_rejections,
        'deviation': deviation,
        'anomaly': anomaly
    })
# --- External Alerting Integration (Email, SMS, Actions) ---
def send_email_alert(subject, body, recipients):
    import smtplib
    from email.mime.text import MIMEText
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = 'soc-alerts@example.com'
    msg['To'] = ','.join(recipients)
    try:
        with smtplib.SMTP('localhost') as server:
            server.sendmail(msg['From'], recipients, msg.as_string())
    except Exception as e:
        print(f"Email alert failed: {e}")

def send_sms_alert(message, numbers):
    # Placeholder for SMS integration (Twilio, etc.)
    for number in numbers:
        print(f"SMS to {number}: {message}")
    # Integrate with Twilio or other provider here

def automate_additional_actions(request):
    # Example: create ticket, log incident, etc.
    print(f"Automated action for request {request['request_id']}: {request['resolution_outcome']}")
    # Integrate with ServiceNow, Jira, etc.

# --- Enhanced notify_resolution ---
def notify_resolution(req, outcome):
    channels = ["#incident-response", "#engineering-leads", "#exec-ops"]
    text = f"✅ Request #{req['request_id']} resolved: retraining triggered." if outcome == 'approved' else f"❌ Request #{req['request_id']} resolved: retraining rejected."
    for channel in channels:
        payload = {
            "channel": channel,
            "text": text,
            "blocks": [
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": f"{text}\nRequested by *{req['requested_by']}* (Reason: {req['reason']}).\nEscalation closed."}
                }
            ]
        }
        requests.post(SLACK_WEBHOOK_URL, json=payload)
    # Email alert
    subject = f"Override Request #{req['request_id']} Resolution"
    body = f"{text}\nRequested by {req['requested_by']} (Reason: {req['reason']})."
    recipients = ['security-team@example.com', 'ops-leads@example.com']
    send_email_alert(subject, body, recipients)
    # SMS alert
    sms_numbers = ['+15551234567', '+15559876543']
    send_sms_alert(body, sms_numbers)
    # Additional automation
    automate_additional_actions(req)
# --- Daily Resolution Summary & External Alerting ---
def send_daily_resolution_summary():
    import csv, datetime
    now = datetime.datetime.now()
    today = now.date()
    requests = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            resolved_time = row.get('resolution_time','')
            status = row.get('status','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    if resolved_dt.date() == today:
                        requests.append(row)
                except Exception:
                    pass
    if not requests:
        return
    approved = sum(1 for r in requests if r['resolution_outcome'] == 'approved')
    rejected = sum(1 for r in requests if r['resolution_outcome'] == 'rejected')
    details = '\n'.join([f"• Request #{r['request_id']} by {r['requested_by']} ({r['reason']}) → {r['resolution_outcome'].upper()}" for r in requests])
    payload = {
        "channel": "#incident-response",
        "text": "📊 Daily Override Resolution Summary",
        "blocks": [
            {"type": "header", "text": {"type": "plain_text", "text": "📊 Daily Override Summary"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": f"✅ Approved: {approved}\n❌ Rejected: {rejected}\n\n{details}"}}
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)

# --- Daily Summary Scheduler ---
def daily_summary_scheduler():
    import threading, time, datetime
    def job():
        while True:
            now = datetime.datetime.now()
            # Run at 18:00 (6 PM)
            if now.hour == 18 and now.minute == 0:
                send_daily_resolution_summary()
                time.sleep(60)
            else:
                time.sleep(30)
    threading.Thread(target=job, daemon=True).start()

# Start daily summary scheduler
daily_summary_scheduler()
# --- Dashboard Daily Summary API ---
@app.route('/api/daily_resolution_summary')
def daily_resolution_summary():
    import csv, datetime
    now = datetime.datetime.now()
    today = now.date()
    requests = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            resolved_time = row.get('resolution_time','')
            status = row.get('status','')
            if status in ('resolved','rejected') and resolved_time:
                try:
                    resolved_dt = datetime.datetime.fromisoformat(resolved_time)
                    if resolved_dt.date() == today:
                        requests.append(row)
                except Exception:
                    pass
    approved = sum(1 for r in requests if r['resolution_outcome'] == 'approved')
    rejected = sum(1 for r in requests if r['resolution_outcome'] == 'rejected')
    details = [
        {
            'request_id': r['request_id'],
            'requested_by': r['requested_by'],
            'reason': r['reason'],
            'outcome': r['resolution_outcome']
        } for r in requests
    ]
    return jsonify({
        'approved': approved,
        'rejected': rejected,
        'details': details
    })
# --- Resolution Trigger & Slack Closure ---
def resolution_check():
    import csv, datetime, threading, time, tempfile
    channels = ["#incident-response", "#engineering-leads", "#exec-ops"]
    while True:
        now = datetime.datetime.now()
        requests = []
        with open('automation/override_requests.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['status'] == 'pending':
                    requests.append(row)
        votes = []
        with open('automation/retraining_override_votes.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                votes.append(row)
        updated_rows = []
        for req in requests:
            req_id = req['request_id']
            approvals_required = int(req['approvals_required'])
            approvals_received = len([v for v in votes if v['request_id']==req_id and v['decision']=='approve'])
            rejections = len([v for v in votes if v['request_id']==req_id and v['decision']=='reject'])
            resolved = False
            outcome = ''
            if approvals_received >= approvals_required:
                req['status'] = 'resolved'
                req['resolution_time'] = now.isoformat()
                req['resolution_by'] = ','.join([v['slack_user'] for v in votes if v['request_id']==req_id and v['decision']=='approve'])
                req['resolution_outcome'] = 'approved'
                resolved = True
                outcome = 'approved'
            elif rejections > 0:
                req['status'] = 'resolved'
                req['resolution_time'] = now.isoformat()
                req['resolution_by'] = ','.join([v['slack_user'] for v in votes if v['request_id']==req_id and v['decision']=='reject'])
                req['resolution_outcome'] = 'rejected'
                resolved = True
                outcome = 'rejected'
            if resolved:
                notify_resolution(req, outcome)
                req['escalation_history'] = (req.get('escalation_history','') + f"Resolution ({outcome}) at {now.isoformat()}|") if req.get('escalation_history','') else f"Resolution ({outcome}) at {now.isoformat()}|"
            updated_rows.append(req)
        # Write back updated status/history
        with tempfile.NamedTemporaryFile('w', delete=False, newline='') as tf:
            writer = csv.DictWriter(tf, fieldnames=updated_rows[0].keys())
            writer.writeheader()
            writer.writerows(updated_rows)
        os.replace(tf.name, 'automation/override_requests.csv')
        time.sleep(300)

def notify_resolution(req, outcome):
    channels = ["#incident-response", "#engineering-leads", "#exec-ops"]
    text = f"✅ Request #{req['request_id']} resolved: retraining triggered." if outcome == 'approved' else f"❌ Request #{req['request_id']} resolved: retraining rejected."
    for channel in channels:
        payload = {
            "channel": channel,
            "text": text,
            "blocks": [
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": f"{text}\nRequested by *{req['requested_by']}* (Reason: {req['reason']}).\nEscalation closed."}
                }
            ]
        }
        requests.post(SLACK_WEBHOOK_URL, json=payload)

# Start resolution thread
threading.Thread(target=resolution_check, daemon=True).start()
# --- Dashboard Resolution Timeline API ---
@app.route('/api/resolution_timeline')
def resolution_timeline():
    import csv
    rows = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('status') == 'resolved':
                rows.append({
                    'request_id': row['request_id'],
                    'resolution_time': row.get('resolution_time',''),
                    'resolution_by': row.get('resolution_by',''),
                    'resolution_outcome': row.get('resolution_outcome',''),
                    'escalation_history': row.get('escalation_history','')
                })
    return jsonify(rows)

# --- Tiered Escalation Logic ---
def tiered_escalation_check():
    import csv, datetime, threading, time, tempfile
    channels = ["#incident-response", "#engineering-leads", "#exec-ops"]
    while True:
        now = datetime.datetime.now()
        requests = []
        with open('automation/override_requests.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['status'] == 'pending':
                    requests.append(row)
        votes = []
        with open('automation/retraining_override_votes.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                votes.append(row)
        updated_rows = []
        for req in requests:
            req_id = req['request_id']
            approvals_required = int(req['approvals_required'])
            approvals_received = len([v for v in votes if v['request_id']==req_id and v['decision']=='approve'])
            expires_at = datetime.datetime.fromisoformat(req['expires_at']) if req['expires_at'] else None
            time_left = (expires_at - now).total_seconds() if expires_at else None
            escalation_level = int(req.get('escalation_level', 0))
            escalation_history = req.get('escalation_history', '')
            one_short = approvals_received == approvals_required - 1
            if one_short and time_left is not None and time_left <= 2*60*60 and time_left > 0:
                next_level = escalation_level + 1
                if next_level < len(channels):
                    # Only escalate if not already at this level
                    if escalation_level < next_level:
                        channel = channels[next_level]
                        text = f"⚠️ Tiered Escalation: Override Request #{req_id}"
                        detail = f"⚠️ *Tiered Escalation*\nRequest #{req_id} by *{req['requested_by']}* (Reason: {req['reason']})\nExpires at: {req['expires_at']}\n\nCurrently *{approvals_received}/{approvals_required} approvals*. Needs one more approval before expiry!"
                        payload = {
                            "channel": channel,
                            "text": text,
                            "blocks": [
                                {
                                    "type": "section",
                                    "text": {"type": "mrkdwn", "text": detail}
                                }
                            ]
                        }
                        requests.post(SLACK_WEBHOOK_URL, json=payload)
                        # Update escalation_level and history
                        escalation_history = (escalation_history + f"Level {next_level} ({channel}) at {now.isoformat()}|") if escalation_history else f"Level {next_level} ({channel}) at {now.isoformat()}|"
                        req['escalation_level'] = str(next_level)
                        req['escalation_history'] = escalation_history
            updated_rows.append(req)
        # Write back updated escalation_level/history
        with tempfile.NamedTemporaryFile('w', delete=False, newline='') as tf:
            writer = csv.DictWriter(tf, fieldnames=updated_rows[0].keys())
            writer.writeheader()
            writer.writerows(updated_rows)
        os.replace(tf.name, 'automation/override_requests.csv')
        time.sleep(1800)

# Start tiered escalation thread
threading.Thread(target=tiered_escalation_check, daemon=True).start()
# --- Dashboard Escalation Timeline API ---
@app.route('/api/escalation_timeline')
def escalation_timeline():
    import csv
    rows = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append({
                'request_id': row['request_id'],
                'escalation_level': row.get('escalation_level', '0'),
                'escalation_history': row.get('escalation_history', '')
            })
    return jsonify(rows)

# --- Dashboard Analytics API ---
@app.route('/api/override_analytics')
def override_analytics():
    import csv, datetime
    requests = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            requests.append(row)
    votes = []
    with open('automation/retraining_override_votes.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            votes.append(row)
    # Analytics: response time, approval rate, escalation frequency
    response_times = []
    approvals = 0
    total = 0
    escalations = 0
    for req in requests:
        if req['status'] == 'approved' and req['timestamp'] and req['approved_by']:
            try:
                t1 = datetime.datetime.fromisoformat(req['timestamp'])
                t2 = datetime.datetime.fromisoformat(req['expires_at'])
                response_times.append((t2-t1).total_seconds())
            except Exception:
                pass
        total += 1
        approvals += int(req['approvals_received'])
        if req['status'] == 'escalated':
            escalations += 1
    avg_response = sum(response_times)/len(response_times) if response_times else 0
    approval_rate = approvals/total if total else 0
    return jsonify({
        'avg_response_time': avg_response,
        'approval_rate': approval_rate,
        'escalation_count': escalations
    })
# --- Multi-level Escalation & Reminders ---
def escalation_and_reminder_check():
    import csv, datetime, threading, time
    while True:
        now = datetime.datetime.now()
        requests = []
        with open('automation/override_requests.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['status'] == 'pending':
                    requests.append(row)
        votes = []
        with open('automation/retraining_override_votes.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                votes.append(row)
        for req in requests:
            req_id = req['request_id']
            approvals_required = int(req['approvals_required'])
            approvals_received = len([v for v in votes if v['request_id']==req_id and v['decision']=='approve'])
            rejections = len([v for v in votes if v['request_id']==req_id and v['decision']=='reject'])
            expires_at = datetime.datetime.fromisoformat(req['expires_at']) if req['expires_at'] else None
            time_left = (expires_at - now).total_seconds() if expires_at else None
            # Level 1 Escalation: one approval short, <2h to expiry
            if approvals_received == approvals_required - 1 and time_left is not None and time_left <= 2*60*60:
                send_escalation_alert(req, approvals_received)
            # Level 2 Escalation: rejected, <2h to expiry
            if rejections > 0 and time_left is not None and time_left <= 2*60*60:
                send_escalation_alert(req, approvals_received)
            # Reminder: all pending requests <2h to expiry
            if time_left is not None and time_left <= 2*60*60 and time_left > 0 and req['reminder_sent'] != 'true':
                send_reminder_alert(req, approvals_received)
                mark_reminder_sent(req_id)
            # Expiration: mark expired
            if time_left is not None and time_left <= 0 and req['status'] == 'pending':
                expire_request(req_id)
        time.sleep(1800)  # Run every 30 min

def send_escalation_alert(req, approvals_received):
    payload = {
        "channel": "#incident-response",
        "text": f"⚠️ Escalation: Override Request #{req['request_id']}",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"⚠️ *Escalation Alert*\nRequest #{req['request_id']} by *{req['requested_by']}* (Reason: {req['reason']})\nExpires at: {req['expires_at']}\n\nCurrently *{approvals_received}/{req['approvals_required']} approvals*. Needs just one more approval before expiry!"
                }
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)

def send_reminder_alert(req, approvals_received):
    payload = {
        "channel": "#incident-response",
        "text": f"⏰ Reminder: Override Request #{req['request_id']} expires soon",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"⏰ *Reminder*\nRequest #{req['request_id']} by *{req['requested_by']}* (Reason: {req['reason']})\nExpires at: {req['expires_at']}\n\nCurrently *{approvals_received}/{req['approvals_required']} approvals*. Please act before expiry!"
                }
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)

def mark_reminder_sent(request_id):
    import csv, tempfile
    rows = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['request_id'] == request_id:
                row['reminder_sent'] = 'true'
            rows.append(row)
    with tempfile.NamedTemporaryFile('w', delete=False, newline='') as tf:
        writer = csv.DictWriter(tf, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tf.name, 'automation/override_requests.csv')

# Start escalation/reminder thread
threading.Thread(target=escalation_and_reminder_check, daemon=True).start()
# --- Escalation & Expiration Automation ---
def escalation_check():
    import csv, datetime, threading, time
    while True:
        now = datetime.datetime.now()
        requests = []
        with open('automation/override_requests.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['status'] == 'pending':
                    requests.append(row)
        votes = []
        with open('automation/retraining_override_votes.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                votes.append(row)
        for req in requests:
            req_id = req['request_id']
            approvals_required = int(req['approvals_required'])
            approvals_received = len([v for v in votes if v['request_id']==req_id and v['decision']=='approve'])
            expires_at = datetime.datetime.fromisoformat(req['expires_at']) if req['expires_at'] else None
            time_left = (expires_at - now).total_seconds() if expires_at else None
            # Escalation: one approval short, <2h to expiry
            if approvals_received == approvals_required - 1 and time_left is not None and time_left <= 2*60*60:
                send_escalation_alert(req, approvals_received)
            # Expiration: mark expired
            if time_left is not None and time_left <= 0 and req['status'] == 'pending':
                expire_request(req_id)
        time.sleep(1800)  # Run every 30 min

def send_escalation_alert(req, approvals_received):
    payload = {
        "channel": "#incident-response",
        "text": f"⚠️ Escalation: Override Request #{req['request_id']}",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"⚠️ *Escalation Alert*\nRequest #{req['request_id']} by *{req['requested_by']}* (Reason: {req['reason']})\nExpires at: {req['expires_at']}\n\nCurrently *{approvals_received}/{req['approvals_required']} approvals*. Needs just one more approval before expiry!"
                }
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)

def expire_request(request_id):
    import csv, tempfile
    rows = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['request_id'] == request_id:
                row['status'] = 'expired'
            rows.append(row)
    with tempfile.NamedTemporaryFile('w', delete=False, newline='') as tf:
        writer = csv.DictWriter(tf, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tf.name, 'automation/override_requests.csv')

# Start escalation check thread
threading.Thread(target=escalation_check, daemon=True).start()
# --- Slack Action Handler for Digest Votes ---
@app.route('/slack/digest_action', methods=['POST'])
def slack_digest_action():
    payload = request.form.get('payload')
    if not payload:
        return 'No payload', 400
    data = json.loads(payload)
    action = data['actions'][0]
    user = data['user']['name']
    action_value = json.loads(action['value']) if action['value'].startswith('{') else action['value']
    request_id = str(action_value['requestId']) if isinstance(action_value, dict) else action_value.split('_')[1]
    decision = 'approve' if action_value['action'] == 'approve_override' else 'reject'
    reason = action_value.get('reason', '') if isinstance(action_value, dict) else ''
    # Record vote with reason
    import csv
    import datetime
    with open('automation/retraining_override_votes.csv', 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([request_id, user, decision, datetime.datetime.now().isoformat(), reason])
    return f"Vote '{decision}' recorded for request {request_id} by {user} (Reason: {reason})"
# --- Dashboard Rejection Reason Analytics API ---
@app.route('/api/rejection_reasons')
def rejection_reasons():
    import csv
    reasons = {}
    with open('automation/retraining_override_votes.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['decision'] == 'reject':
                r = row.get('reason','Other') or 'Other'
                reasons[r] = reasons.get(r,0) + 1
    return jsonify(reasons)

# --- Real-time Dashboard API for Override Progress ---
@app.route('/api/override_progress')
def override_progress():
    import csv
    requests = []
    with open('automation/override_requests.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            requests.append(row)
    votes = []
    with open('automation/retraining_override_votes.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            votes.append(row)
    for req in requests:
        req_id = req['request_id']
        req['approvals_received'] = str(len([v for v in votes if v['request_id']==req_id and v['decision']=='approve'))
        req['rejections'] = str(len([v for v in votes if v['request_id']==req_id and v['decision']=='reject'))
    return jsonify(requests)
# --- Override Request Digest & Consensus ---
OVERRIDE_REQUESTS_FILE = 'automation/override_requests.csv'

def schedule_daily_digest():
    import threading
    def digest_job():
        while True:
            send_daily_digest()
            time.sleep(86400)  # Run every 24 hours
    threading.Thread(target=digest_job, daemon=True).start()

def send_daily_digest():
    import csv
    import datetime
    now = datetime.datetime.now()
    digest_requests = []
    with open(OVERRIDE_REQUESTS_FILE) as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['digest_sent'] != 'yes' and row['status'] == 'pending':
                digest_requests.append(row)
    if digest_requests:
        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Daily Override Requests Digest* ({now.strftime('%Y-%m-%d')})"
                }
            }
        ]
        for req in digest_requests:
            consensus = f"{req['approvals_received']}/{req['approvals_required']} approvals"
            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"Request #{req['request_id']} by {req['requested_by']}\nReason: {req['reason']}\nConsensus: {consensus}\nExpires: {req['expires_at']}"
                }
            })
            blocks.append({
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Approve"},
                        "style": "primary",
                        "value": f"approve_{req['request_id']}"
                    },
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Reject"},
                        "style": "danger",
                        "value": f"reject_{req['request_id']}"
                    }
                ]
            })
        payload = {
            "channel": "#incident-response",
            "text": "Daily Override Requests Digest",
            "blocks": blocks
        }
        requests.post(SLACK_WEBHOOK_URL, json=payload)
        # Mark digest_sent for these requests
        update_digest_sent([r['request_id'] for r in digest_requests])

def update_digest_sent(request_ids):
    import csv
    import tempfile
    rows = []
    with open(OVERRIDE_REQUESTS_FILE) as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['request_id'] in request_ids:
                row['digest_sent'] = 'yes'
            rows.append(row)
    with tempfile.NamedTemporaryFile('w', delete=False, newline='') as tf:
        writer = csv.DictWriter(tf, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tf.name, OVERRIDE_REQUESTS_FILE)

def get_consensus_progress(request_id):
    import csv
    with open(OVERRIDE_REQUESTS_FILE) as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['request_id'] == str(request_id):
                return f"{row['approvals_received']}/{row['approvals_required']} approvals"
    return "N/A"

# Start digest scheduler on app launch
schedule_daily_digest()
RETRAINING_PERMISSIONS_FILE = 'automation/retraining_permissions.csv'
RETRAINING_OVERRIDE_AUDIT_FILE = 'automation/retraining_override_audit.csv'
def get_user_role(slack_user):
    import csv
    try:
        with open(RETRAINING_PERMISSIONS_FILE) as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['slack_user'] == slack_user:
                    return row['role']
    except Exception:
        pass
    return None
def log_override_attempt(slack_user, action, result, reason):
    import datetime
    ts = datetime.datetime.now().isoformat()
    with open(RETRAINING_OVERRIDE_AUDIT_FILE, 'a') as f:
        f.write(f"{ts},{slack_user},{action},{result},{reason}\n")
from flask import request
# Immediate retraining and override logging
def schedule_retraining_immediate(reason, user):
    import subprocess
    import datetime
    try:
        subprocess.Popen(['python', 'retrain_sla_model.py'])
        # Log override event
        with open(RETRAINING_EVENTS_FILE, 'a') as f:
            ts = datetime.datetime.now().isoformat()
            f.write(f"{ts},Forced retraining by {user}: {reason}\n")
    except Exception as e:
        print(f"Immediate retraining failed: {e}")

@app.route('/slack/actions', methods=['POST'])
def slack_actions():
    payload = request.form.get('payload')
    if not payload:
        return 'No payload', 400
    data = json.loads(payload)
    action = json.loads(data['actions'][0]['value'])
    user = data['user']['name']
    if action.get('action') == 'force_retrain':
        role = get_user_role(user)
        if role not in ['senior_engineer', 'admin']:
            log_override_attempt(user, 'force_retrain', 'denied', action.get('reason', ''))
            return f"🚫 Retraining override denied. {user} does not have permission."
        schedule_retraining_immediate(action.get('reason', ''), user)
        log_override_attempt(user, 'force_retrain', 'approved', action.get('reason', ''))
        return f"⚙️ Retraining forced by {user}."
    return 'No action taken.'
# Slack notification for cooldown skip
def notify_slack_cooldown_skip(reason, next_eligible):
    payload = {
        "channel": "#incident-response",
        "text": "🔴 Retraining Skipped (Cooldown Active)",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"🔴 *Retraining Skipped*\nReason: {reason}\nCooldown active. Next eligible retraining date: *{next_eligible.strftime('%Y-%m-%d')}*"
                }
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Force Retraining Now"},
                        "style": "primary",
                        "value": f"{{\"action\": \"force_retrain\", \"reason\": \"{reason}\"}}"
                    }
                ]
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)
import subprocess
import datetime
RETRAINING_EVENTS_FILE = 'automation/retraining_events.csv'
@app.route('/api/model_accuracy')
def model_accuracy():
    import pandas as pd
    import numpy as np
    # Load predictions and breaches
    pred_df = pd.read_csv('automation/sla_predictions.csv')
    breach_df = pd.read_csv('automation/sla_breaches.csv')
    pred_df['day'] = pd.to_datetime(pred_df['created_at']).dt.date
    breach_df['day'] = pd.to_datetime(breach_df['Time'], format='%H:%M').dt.date
    breach_days = set(breach_df['day'])
    tp = fp = tn = fn = 0
    for _, row in pred_df.iterrows():
        threshold = get_sla_threshold()
        predicted = row['predicted_risk'] > threshold
        actual = row['day'] in breach_days
        if predicted and actual:
            tp += 1
        elif predicted and not actual:
            fp += 1
        elif not predicted and not actual:
            tn += 1
        elif not predicted and actual:
            fn += 1
    precision = tp / (tp + fp) if (tp + fp) else 0
    recall = tp / (tp + fn) if (tp + fn) else 0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) else 0
    accuracy = (tp + tn) / (tp + tn + fp + fn) if (tp + tn + fp + fn) else 0
            def notify_sla_risk(risk_score): 
    new_threshold = orig_threshold
    if precision < 0.7:
        new_threshold += 0.05
    elif recall < 0.7:
        new_threshold -= 0.05
    new_threshold = max(0.3, min(0.7, new_threshold))
    last_threshold = get_last_threshold()
    if new_threshold != orig_threshold:
        set_sla_threshold(new_threshold)
        log_threshold_adjustment(new_threshold, precision, recall, f1, accuracy)
        # Notify Slack if change ≥ 0.05
        if abs(new_threshold - last_threshold) >= 0.05:
            notify_slack_threshold_change(last_threshold, new_threshold, {
                'precision': precision,
                'recall': recall,
                'f1': f1,
                'accuracy': accuracy
            })
    return jsonify({
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'accuracy': accuracy,
        'threshold': new_threshold
    })
import tensorflow as tf
import numpy as np
def load_sla_model():
    try:
        return tf.keras.models.load_model('sla_model')
    except Exception:
        return None

def predict_sla_risk(incident_count):
    model = load_sla_model()
    if model:

            # --- Correlation Detection & Slack Alert ---
            def notify_slack_accuracy_drop(rejections, accuracy):
                payload = {
                    "channel": "#incident-response",
                    "text": "⚠️ Model Accuracy Drop Detected",
                    "blocks": [
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": f"⚠️ *Model Accuracy Alert*\nAccuracy fell to *{(accuracy*100):.1f}%* after *{rejections} rejections* this week.\n\nConsider reviewing auto‑adjustment logic or retraining schedule."
                            }
                        }
                    ]
                }
                requests.post(SLACK_WEBHOOK_URL, json=payload)

            def check_rejection_impact():
                import pandas as pd
                df = pd.read_csv(THRESHOLD_HISTORY_FILE)
                df = df[df['decision'].notnull()]
                df['week'] = pd.to_datetime(df['decided_at']).dt.to_period('W').astype(str)
                grouped = df.groupby('week').agg(
                    rejected=('decision', lambda x: (x == 'rejected').sum()),
                    avg_accuracy=('accuracy', 'mean')
                ).reset_index().sort_values('week', ascending=False)
                if len(grouped) < 2:
                    return False
                latest, prev = grouped.iloc[0], grouped.iloc[1]
                if latest['rejected'] >= 3 and latest['avg_accuracy'] < prev['avg_accuracy'] - 0.05:
                    notify_slack_accuracy_drop(latest['rejected'], latest['avg_accuracy'])
                    # Enforce retraining cooldown
                    import csv
                    import os
                    cooldown_days = 7
                    now = datetime.datetime.now()
                    last_run = None
                    if os.path.exists(RETRAINING_EVENTS_FILE):
                        with open(RETRAINING_EVENTS_FILE) as f:
                            reader = csv.DictReader(f)
                            rows = list(reader)
                            if rows:
                                last_run = rows[-1]['timestamp']
                    allow_retraining = False
                    if not last_run:
                        allow_retraining = True
                    else:
                        last_dt = datetime.datetime.fromisoformat(last_run)
                        if (now - last_dt).days >= cooldown_days:
                            allow_retraining = True
                    if allow_retraining:
                        try:
                            subprocess.Popen(['python', 'retrain_sla_model.py'])
                            # Log retraining event
                            with open(RETRAINING_EVENTS_FILE, 'a') as f:
                                ts = now.isoformat()
                                reason = f"Accuracy drop after {latest['rejected']} rejections"
                                f.write(f"{ts},{reason}\n")
                        except Exception as e:
                            print(f"Retraining scheduling failed: {e}")
                    else:
                        next_eligible = last_dt + datetime.timedelta(days=cooldown_days)
                        notify_slack_cooldown_skip(f"Accuracy drop after {latest['rejected']} rejections", next_eligible)
                        print("Retraining skipped: cooldown active.")
                    return True
                return False
                return False
        x = np.array([[incident_count]])
        return float(model.predict(x)[0][0])
    else:
        return 0.65  # fallback

def get_model_accuracy():
    try:
        with open('sla_model_accuracy.txt') as f:
            return float(f.read().strip())
    except Exception:
        return 72.0
import requests
import time
# --- SLA Risk Forecast & Notification ---
SLA_RISK_THRESHOLD = 0.5
SLA_RISK_STATE = {'last_alert_time': None, 'last_ack': None, 'last_escalation': None}
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL') or 'https://hooks.slack.com/services/your/webhook/url'

def get_sla_threshold():
    try:
        with open('sla_threshold.txt') as f:
            return float(f.read().strip())
    except Exception:
        return 0.5

def set_sla_threshold(value):
    with open('sla_threshold.txt', 'w') as f:
        f.write(str(round(value, 2)))

# Patch notify_sla_risk to use dynamic threshold
def notify_sla_risk(risk_score):
    threshold = get_sla_threshold()
    if risk_score > threshold:
        payload = {
            "channel": "#incident-response",
            "text": f"⚠️ SLA Risk Alert: Predicted breach risk {int(risk_score * 100)}%",
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"⚠️ SLA Risk Alert\nPredicted breach risk: *{int(risk_score * 100)}%*"
                    }
                },
                {
                    "type": "actions",
                    "elements": [
                        {
                            "type": "button",
                            "text": {"type": "plain_text", "text": "Acknowledge"},
                            "style": "primary",
                            "value": "acknowledge_sla_risk"
                        },
                        {
                            "type": "button",
                            "text": {"type": "plain_text", "text": "Escalate"},
                            "style": "danger",
                            "value": "escalate_sla_risk"
                        }
                    ]
                }
            ]
        }
        requests.post(SLACK_WEBHOOK_URL, json=payload)
        SLA_RISK_STATE['last_alert_time'] = time.time()
        SLA_RISK_STATE['last_ack'] = None
        SLA_RISK_STATE['last_escalation'] = None

def escalate_sla_risk():
    now = time.time()
    if SLA_RISK_STATE['last_alert_time'] and not SLA_RISK_STATE['last_ack']:
        elapsed = now - SLA_RISK_STATE['last_alert_time']
        if elapsed > 1800 and not SLA_RISK_STATE['last_escalation']:
            # Escalate to manager
            payload = {
                "channel": "#incident-response",
                "text": "🚨 SLA Risk Escalation: Alert not acknowledged in 30 min. Escalating to manager.",
            }
            requests.post(SLACK_WEBHOOK_URL, json=payload)
            SLA_RISK_STATE['last_escalation'] = now
        elif SLA_RISK_STATE['last_escalation'] and (now - SLA_RISK_STATE['last_escalation'] > 1800):
            # Escalate to director
            payload = {
                "channel": "#incident-response",
                "text": "🚨 SLA Risk Escalation: Alert still unacknowledged. Escalating to director.",
            }
            requests.post(SLACK_WEBHOOK_URL, json=payload)
            SLA_RISK_STATE['last_escalation'] = now

@app.route('/api/sla_risk_forecast')
def sla_risk_forecast():
    # Use today's incident count
    import datetime
    today = datetime.date.today()
    incidents = 0
    try:
        with open('automation/incidents.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                day = datetime.datetime.strptime(row['Time'], '%H:%M').date()
                if day == today:
                    incidents += 1
    except Exception:
        pass
    risk_score = predict_sla_risk(incidents)
    threshold = get_sla_threshold()
    notify_sla_risk(risk_score)
    escalate_sla_risk()
    accuracy = get_model_accuracy()
    return jsonify({"risk_score": risk_score, "threshold": threshold, "model_accuracy": accuracy})
import threading
push_subscriptions = []
@app.route('/api/send_push', methods=['POST'])
def send_push():
    # Simulate sending push to all registered subscriptions
    data = request.get_json()
    message = data.get('message', 'SOC Alert!')
    # In production, use pywebpush or similar to send to all push_subscriptions
    print('Sending push:', message)
    # For demo, just print and return success
    return jsonify({'status': 'sent', 'message': message})

@app.route('/api/audit_type_breakdown')
def audit_type_breakdown():
    # Simulate event type breakdown
    types = ['phishing', 'malware', 'escalation', 'success', 'failure', 'warning']
    import random
    counts = [random.randint(5, 30) for _ in types]
    return jsonify({'types': types, 'counts': counts})
@app.route('/api/register_push', methods=['POST'])
def register_push():
    # Simulate storing push subscription (in-memory)
    sub = request.get_json()
    push_subscriptions.append(sub)
    print('Push subscription received:', sub)
    return jsonify({'status': 'registered'})

@app.route('/api/audit_trend')
def audit_trend():
    # Simulate daily event trend (last 7 days)
    import datetime
    today = datetime.date.today()
    dates = [(today - datetime.timedelta(days=i)).strftime('%Y-%m-%d') for i in range(6,-1,-1)]
    # Simulate counts (random or from log)
    import random
    counts = [random.randint(10, 30) for _ in dates]
    return jsonify({'dates': dates, 'counts': counts})
from flask import Flask, render_template, request, jsonify, send_file
import csv
@app.route('/api/incidents_vs_sla')
def incidents_vs_sla():
    import datetime
    from collections import Counter
    # Read incidents
    incident_counts = Counter()
    with open('automation/incidents.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            day = datetime.datetime.strptime(row['Time'], '%H:%M').date()
            incident_counts[day] += 1
    # Read SLA breaches
    sla_counts = Counter()
    with open('automation/sla_breaches.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            day = datetime.datetime.strptime(row['Time'], '%H:%M').date()
            sla_counts[day] += 1
    # Generate last 30 days
    today = datetime.date.today()
    days = [(today - datetime.timedelta(days=i)) for i in range(29, -1, -1)]
    result = []
    for day in days:
        result.append({
            'day': day.strftime('%Y-%m-%d'),
            'incidents': incident_counts.get(day, 0),
            'breaches': sla_counts.get(day, 0)
        })
    return jsonify(result)
import json
import datetime
from fpdf import FPDF
import os

app = Flask(__name__)

# Paths for data persistence
LOG_FILE = "phishing_events.log"
DASHBOARD_DATA = "dashboard_data.json"

def log_to_file(entry):
    entry = fisher_engine_threat_patterns(entry)
    old_log_to_file(entry)

@app.route('/')
def index():
    return render_template('soc_dashboard.html')

@app.route('/api/feed')
def get_feed():
    # Reads the latest state for the UI Live Feed
    if os.path.exists(DASHBOARD_DATA):
        with open(DASHBOARD_DATA, "r") as f:
            return jsonify(json.load(f))
    return jsonify({"status": "no_data"})

@app.route('/api/block', methods=['POST'])
def block_domain():
    data = request.json
    target_domain = data.get('domain')
    # 🛡️ Integration Point: Trigger Firewall/DNS Block
    print(f"ACTION: Blocked {target_domain} at Perimeter.")
    log_entry = {
        "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "event": "BLOCK_EXECUTED",
        "domain": target_domain,
        "operator": "SOC_ANALYST_01" # Integrates with RBAC principle
    }
    log_to_file(log_entry)
    return jsonify({"status": "success", "message": f"Domain {target_domain} blocked."})

@app.route('/api/report')
def generate_report():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(200, 10, txt="SOC Incident Audit Report", ln=True, align='C')
    pdf.set_font("Arial", size=10)
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            for line in f:
                pdf.multi_cell(0, 10, txt=line)
    report_path = "SOC_Daily_Audit.pdf"
    pdf.output(report_path)
    return send_file(report_path, as_attachment=True)

@app.route('/api/system_health')
def system_health():
    # Example: Return system health status
    health = {
        "status": "healthy",
        "uptime": "99.99%",
        "last_check": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "alerts": 0
    }
    return jsonify(health)

@app.route('/api/user_stats')
def user_stats():
    # Example: Return user statistics
    stats = {
        "active_users": 12,
        "admins": 3,
        "last_login": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "roles": {"admin": 3, "dev": 5, "qa": 2, "viewer": 2}
    }
    return jsonify(stats)

@app.route('/api/escalation_summary')
def escalation_summary():
    # Example: Return escalation summary from log
    results = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            for line in f:
                entry = json.loads(line)
                if "escalation" in entry.get("event", "").lower():
                    results.append(entry)
    return jsonify({"count": len(results), "escalations": results})

@app.route('/api/retry_summary')
def retry_summary():
    # Example: Return retry summary from log
    results = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            for line in f:
                entry = json.loads(line)
                if "retry" in entry.get("event", "").lower():
                    results.append(entry)
    return jsonify({"count": len(results), "retries": results})

@app.route('/api/ml_prediction_summary')
def ml_prediction_summary():
    # Example: Return ML prediction summary (simulated)
    summary = {
        "accuracy": 97.2,
        "predictions": [
            {"timestamp": "2026-03-05 09:00:00", "predicted": "High", "actual": "High"},
            {"timestamp": "2026-03-05 10:00:00", "predicted": "Medium", "actual": "Medium"}
        ]
    }
    return jsonify(summary)

@app.route('/api/notification_status')
def notification_status():
    # Example: Return notification delivery status (simulated)
    status = {
        "delivered": 25,
        "pending": 2,
        "failed": 1,
        "last_delivery": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    return jsonify(status)

@app.route('/api/audit_trail_filtered')
def audit_trail_filtered():
    # Example: Filter audit trail by event type (query param)
    event_type = request.args.get('type', '').lower()
    results = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            for line in f:
                entry = json.loads(line)
                if event_type in entry.get("event", "").lower():
                    results.append(entry)
    return jsonify(results)

@app.route('/api/incident_summary')
def incident_summary():
    # Example: Return incident summary from log
    incidents = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            for line in f:
                entry = json.loads(line)
                if "incident" in entry.get("event", "").lower():
                    incidents.append(entry)
    return jsonify({"count": len(incidents), "incidents": incidents})

@app.route('/api/compliance_status')
def compliance_status():
    # Example: Return compliance status (simulated)
    status = {
        "compliant": True,
        "last_audit": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "issues": 0,
        "details": "All controls passed. No open issues."
    }
    return jsonify(status)

@app.route('/api/plugin_status')
def plugin_status():
    # Example: Return plugin integration status (simulated)
    plugins = [
        {"name": "Jira", "status": "active", "last_sync": "2026-03-05 08:00:00"},
        {"name": "ServiceNow", "status": "active", "last_sync": "2026-03-05 08:05:00"},
        {"name": "Slack Bot", "status": "inactive", "last_sync": "2026-03-04 18:00:00"}
    ]
    return jsonify({"plugins": plugins})

@app.route('/api/scheduled_tasks')
def scheduled_tasks():
    # Example: Return scheduled tasks (simulated)
    tasks = [
        {"task": "Daily Audit Report", "status": "completed", "next_run": "2026-03-06 08:00:00"},
        {"task": "Weekly Compliance Scan", "status": "pending", "next_run": "2026-03-10 09:00:00"}
    ]
    return jsonify({"tasks": tasks})

@app.route('/api/escalation_policy_details')
def escalation_policy_details():
    # Example: Return escalation policy details (simulated)
    policies = [
        {"level": 1, "action": "Notify Admin", "threshold": "1 tampering", "message": "First detection"},
        {"level": 2, "action": "Escalate to SOC Lead", "threshold": "2 tampering", "message": "Persistent tampering"},
        {"level": 3, "action": "Lock System", "threshold": "3+ tampering", "message": "Critical tampering"}
    ]
    return jsonify({"policies": policies})

@app.route('/api/threat_intel')
def threat_intel():
    # Example: Return threat intelligence (simulated)
    intel = [
        {"threat": "Phishing", "severity": "High", "indicator": "malicious-domain.com", "action": "Blocked"},
        {"threat": "Malware", "severity": "Medium", "indicator": "infected-file.exe", "action": "Quarantined"}
    ]
    return jsonify({"intel": intel})

@app.route('/api/open_tickets')
def open_tickets():
    # Example: Return open support tickets (simulated)
    tickets = [
        {"id": "DEPLOY-1234", "type": "Jira", "status": "open", "summary": "Escalation triggered for Team A"},
        {"id": "INC-5678", "type": "ServiceNow", "status": "open", "summary": "Critical tampering detected"}
    ]
    return jsonify({"tickets": tickets})

@app.route('/api/scheduled_maintenance')
def scheduled_maintenance():
    # Example: Return scheduled maintenance events (simulated)
    maintenance = [
        {"window": "2026-03-07 02:00-04:00", "system": "Firewall", "action": "Upgrade"},
        {"window": "2026-03-10 01:00-03:00", "system": "SIEM", "action": "Patch"}
    ]
    return jsonify({"maintenance": maintenance})

@app.route('/api/escalation_actions')
def escalation_actions():
    # Example: Return escalation actions taken (simulated)
    actions = [
        {"timestamp": "2026-03-05 09:15:00", "action": "Lockdown", "details": "System locked due to critical tampering"},
        {"timestamp": "2026-03-05 09:20:00", "action": "Notify Admin", "details": "Admin notified for persistent tampering"}
    ]
    return jsonify({"actions": actions})

@app.route('/api/audit_summary')
def audit_summary():
    # Example: Return audit summary (simulated)
    summary = {
        "total_events": 120,
        "last_event": "2026-03-05 10:00:00",
        "critical": 2,
        "warnings": 5,
        "success": 113
    }
    return jsonify(summary)

@app.route('/api/decision_trend')
def decision_trend():
    df = pd.read_csv(THRESHOLD_HISTORY_FILE)
    df = df[df['decision'].notnull()]
    df['week'] = pd.to_datetime(df['decided_at']).dt.to_period('W').astype(str)
    grouped = df.groupby('week').agg(
        approved=('decision', lambda x: (x == 'approved').sum()),
        rejected=('decision', lambda x: (x == 'rejected').sum())
    ).reset_index()
    return jsonify(grouped.to_dict(orient='records'))

@app.route('/api/decision_accuracy_trend')
def decision_accuracy_trend():
    df = pd.read_csv(THRESHOLD_HISTORY_FILE)
    df = df[df['decision'].notnull()]
    df['week'] = pd.to_datetime(df['decided_at']).dt.to_period('W').astype(str)
    grouped = df.groupby('week').agg(
        approved=('decision', lambda x: (x == 'approved').sum()),
        rejected=('decision', lambda x: (x == 'rejected').sum()),
        avg_f1=('f1', 'mean'),
        avg_accuracy=('accuracy', 'mean')
    ).reset_index()
    return jsonify(grouped.to_dict(orient='records'))

@app.route('/api/decision_vs_accuracy')
def decision_vs_accuracy():
    df = pd.read_csv(THRESHOLD_HISTORY_FILE)
    df = df[df['decision'].notnull()]
    df['week'] = pd.to_datetime(df['decided_at']).dt.to_period('W').astype(str)
    grouped = df.groupby('week').agg(
        approved=('decision', lambda x: (x == 'approved').sum()),
        rejected=('decision', lambda x: (x == 'rejected').sum()),
        avg_f1=('f1', 'mean'),
        avg_accuracy=('accuracy', 'mean')
    ).reset_index()
    return jsonify(grouped.to_dict(orient='records'))

if __name__ == '__main__':
    app.run(debug=True, port=5000)

    # --- Clearance Decorator Integration ---
    from middleware import require_clearance

    # Example: Secure Delivery Endpoint (Level 3)
    @app.route('/api/v1/delivery/secure', methods=['POST'])
    @require_clearance('financial_records')
    def secure_delivery():
        # BlueMailer execution logic placeholder
        return jsonify({"status": "dispatched"})

    # Example: Fisher Score Analytics Endpoint (Level 2)
    @app.route('/api/v1/analytics/fisher-score', methods=['GET'])
    @require_clearance('business_credentials')
    def get_analytics():
        # FisherEngine scoring logic placeholder
        return jsonify({"anomaly_score": 0.004})

    # Example: Incident Response Endpoint (Level 1)
    @app.route('/api/v1/incident/response', methods=['POST'])
    @require_clearance('standard_comms')
    def incident_response():
        # Incident response logic placeholder
        return jsonify({"status": "incident logged"})

    # Example: Identity Strike Endpoint (Level 2)
    @app.route('/api/v1/identity/strike', methods=['POST'])
    @require_clearance('business_credentials')
    def identity_strike():
        # Identity strike logic placeholder
        return jsonify({"status": "identity anomaly detected"})

    # Example: Secure Audit Export Endpoint (Level 3)
    @app.route('/api/v1/audit/export', methods=['POST'])
    @require_clearance('audit_exports')
    def audit_export():
        # Secure audit export logic placeholder
        return jsonify({"status": "audit exported securely"})

import pandas as pd
import csv
from datetime import datetime

THRESHOLD_HISTORY_FILE = 'automation/threshold_history.csv'

def log_threshold_adjustment(threshold, precision, recall, f1, accuracy):
    # Append to CSV
    try:
        df = pd.read_csv(THRESHOLD_HISTORY_FILE)
        next_id = df['id'].max() + 1 if not df.empty else 1
    except Exception:
        next_id = 1
    with open(THRESHOLD_HISTORY_FILE, 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            next_id,
            round(threshold, 2),
            round(precision, 4),
            round(recall, 4),
            round(f1, 4),
            round(accuracy, 4),
            datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
        ])

def get_last_threshold():
    try:
        df = pd.read_csv(THRESHOLD_HISTORY_FILE)
        if not df.empty:
            return float(df.iloc[-1]['threshold'])
    except Exception:
        pass
    return get_sla_threshold()

def notify_slack_threshold_change(oldT, newT, metrics):
    payload = {
        "channel": "#incident-response",
        "text": f"🔄 Prediction Threshold Adjustment Proposed: {oldT:.2f} → {newT:.2f}",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (
                        f"🔄 *Threshold Adjustment Proposed*\n"
                        f"From *{oldT:.2f}* → *{newT:.2f}*\n\n"
                        f"Precision: {(metrics['precision']*100):.1f}%\n"
                        f"Recall: {(metrics['recall']*100):.1f}%\n"
                        f"F1: {(metrics['f1']*100):.1f}%\n"
                        f"Accuracy: {(metrics['accuracy']*100):.1f}%"
                    )
                }
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Approve"},
                        "style": "primary",
                        "value": json.dumps({"action": "approve", "newThreshold": newT})
                    },
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Reject"},
                        "style": "danger",
                        "value": json.dumps({"action": "reject", "oldThreshold": oldT})
                    }
                ]
            }
        ]
    }
    requests.post(SLACK_WEBHOOK_URL, json=payload)

@app.route('/slack/actions', methods=['POST'])
def slack_actions():
    payload = json.loads(request.form.get('payload'))
    action = json.loads(payload['actions'][0]['value'])
    user = payload['user']['name']
    now = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    df = pd.read_csv(THRESHOLD_HISTORY_FILE)
    if action['action'] == 'approve':
        # Find last matching threshold row
        idx = df[df['threshold'] == action['newThreshold']].index[-1]
        df.at[idx, 'decision'] = 'approved'
        df.at[idx, 'decided_by'] = user
        df.at[idx, 'decided_at'] = now
        df.to_csv(THRESHOLD_HISTORY_FILE, index=False)
        set_sla_threshold(action['newThreshold'])
        return "✅ Threshold adjustment approved."
    else:
        idx = df[df['threshold'] == action['oldThreshold']].index[-1]
        df.at[idx, 'decision'] = 'rejected'
        df.at[idx, 'decided_by'] = user
        df.at[idx, 'decided_at'] = now
        df.to_csv(THRESHOLD_HISTORY_FILE, index=False)
        return "❌ Threshold adjustment rejected."
