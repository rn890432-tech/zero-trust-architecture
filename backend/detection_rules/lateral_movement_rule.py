def detect_lateral_movement(events):
    for e in events:
        if e["event_type"] == "lateral_movement":
            return {
                "alert":"Suspicious lateral movement detected",
                "source_ip":e["source_ip"]
            }
