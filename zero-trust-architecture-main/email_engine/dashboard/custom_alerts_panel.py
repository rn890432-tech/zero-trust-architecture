from flask import Blueprint, jsonify

custom_alerts_panel = Blueprint('custom_alerts_panel', __name__)

@custom_alerts_panel.route('/api/custom-alerts')
def get_custom_alerts():
    return jsonify({"alerts": [
        {"type": "Bounce Spike", "severity": "high", "timestamp": "2026-03-07"},
        {"type": "SLA Breach", "severity": "medium", "timestamp": "2026-03-06"}
    ]})
