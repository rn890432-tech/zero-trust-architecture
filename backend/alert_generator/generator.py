def generate_alert(alert_type, severity, source_ip, target_user):
    return {
        "alert_type": alert_type,
        "severity": severity,
        "source_ip": source_ip,
        "target_user": target_user
    }
