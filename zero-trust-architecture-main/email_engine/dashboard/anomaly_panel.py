from flask import Blueprint, jsonify

anomaly_panel = Blueprint('anomaly_panel', __name__)

@anomaly_panel.route('/api/anomaly')
def get_anomaly():
    return jsonify({"anomaly_score": 0.87, "recent_anomalies": ["Bounce spike", "Unusual open rate"], "trend": [0.2, 0.4, 0.6, 0.87]})
