import time

def load_incident_history():
    # Placeholder: load from file/db
    return [
        {"timestamp": "02:14", "event": "Login attempt"},
        {"timestamp": "02:15", "event": "Credential theft"},
        {"timestamp": "02:17", "event": "Lateral movement"},
        {"timestamp": "02:19", "event": "Data access"}
    ]

def replay_events(events):
    for e in events:
        print(f"{e['timestamp']} - {e['event']}")
        time.sleep(1)

if __name__ == "__main__":
    history = load_incident_history()
    replay_events(history)
