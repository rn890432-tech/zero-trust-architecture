import json, datetime, sys, time

def log_event(event_type, details):
    entry = {
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "event_type": event_type,
        "details": details
    }
    print(json.dumps(entry), file=sys.stdout)

# Additional metric logging

def log_sla_trend(data):
    log_event("sla_trend", {"value": data["metrics"]["sla_compliance"]})

def log_escalation_count(escalations):
    log_event("red_button_escalation", {"count": len(escalations)})

def log_forecasted_breaches(data):
    log_event("forecasted_breaches", {"count": data["metrics"]["forecasted_breaches"]})

def log_escalation_severity_distribution(escalations):
    severity_counts = {"Critical": 0, "High": 0, "Medium": 0, "Low": 0}
    for e in escalations:
        sev = e[2] if isinstance(e, list) else e.get("severity", "Unknown")
        if sev in severity_counts:
            severity_counts[sev] += 1
    log_event("escalation_severity_distribution", severity_counts)

def log_deck_run_duration(start_time):
    duration = time.time() - start_time
    log_event("deck_run_duration", {"seconds": duration})

def log_deck_error_count(error_count):
    log_event("deck_error_count", {"count": error_count})

def log_weekly_deck_run_success(success_count, total_runs):
    rate = success_count / max(total_runs, 1)
    log_event("weekly_deck_run_success_rate", {"rate": rate, "success_count": success_count, "total_runs": total_runs})

def log_chart_rendering_latency(latency_seconds):
    log_event("chart_rendering_latency", {"seconds": latency_seconds})

def log_alert_delivery_count(alert_type, count):
    log_event("alert_delivery_count", {"alert_type": alert_type, "count": count})
