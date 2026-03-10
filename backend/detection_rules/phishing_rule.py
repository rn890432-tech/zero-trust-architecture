def detect_phishing(events):
    for e in events:
        if e["event_type"] == "phishing_email":
            return {
                "alert":"Phishing attempt detected",
                "source_ip":e["source_ip"]
            }
