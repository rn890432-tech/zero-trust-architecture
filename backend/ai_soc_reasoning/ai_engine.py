import random

def cluster_alerts(alerts):
    # Placeholder: group by source_ip
    clusters = {}
    for alert in alerts:
        key = alert.get("source_ip", "unknown")
        clusters.setdefault(key, []).append(alert)
    return clusters

def generate_incident_summary(cluster):
    return f"{len(cluster)} related alerts from {cluster[0]['source_ip']}"

def recommend_action(cluster):
    return "Block IP and reset credentials"

def assign_priority(cluster):
    return random.choice(["Low", "Medium", "High"])

def analyze_incident(alerts):
    clusters = cluster_alerts(alerts)
    results = []
    for key, cluster in clusters.items():
        summary = generate_incident_summary(cluster)
        action = recommend_action(cluster)
        priority = assign_priority(cluster)
        confidence = round(random.uniform(0.7, 1.0), 2)
        results.append({
            "incident_summary": summary,
            "recommended_action": action,
            "priority": priority,
            "confidence_score": confidence
        })
    return results

if __name__ == "__main__":
    sample_alerts = [
        {"source_ip": "192.168.1.10"},
        {"source_ip": "192.168.1.10"},
        {"source_ip": "10.0.0.5"}
    ]
    incidents = analyze_incident(sample_alerts)
    print(incidents)
