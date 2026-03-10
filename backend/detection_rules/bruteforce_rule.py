def detect_bruteforce(events):
    failed = {}
    for e in events:
        if e["event_type"] == "login_failed":
            ip = e["source_ip"]
            failed[ip] = failed.get(ip,0) + 1
            if failed[ip] > 20:
                return {
                    "alert":"Brute force detected",
                    "source_ip":ip
                }
