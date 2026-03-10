from flask import Blueprint, jsonify

advanced_metrics_panel = Blueprint('advanced_metrics_panel', __name__)

@advanced_metrics_panel.route('/api/advanced-metrics')
def get_advanced_metrics():
    # Example: device and geo stats, deliverability trend, bounce by region, incident types, median resolution
    import statistics
    bounce_by_region = {"US": 3.2, "EU": 2.8, "Asia": 4.1}
    incident_types = {"Phishing": 5, "Malware": 2, "Spam": 8}
    resolution_times = [120, 90, 150, 110, 100]
    median_resolution_time = statistics.median(resolution_times)
    return jsonify({
        "device": {"mobile": 700, "desktop": 500},
        "geo": {"US": 800, "EU": 300, "Asia": 100},
        "deliverability": [98, 97, 99, 96],
        "bounce_by_region": bounce_by_region,
        "incident_types": incident_types,
        "median_resolution_time": median_resolution_time
    })
