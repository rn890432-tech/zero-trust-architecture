from flask import Blueprint, jsonify

threat_intel_panel = Blueprint('threat_intel_panel', __name__)

@threat_intel_panel.route('/api/threat-intel')
def get_threat_intel():
    return jsonify({"active_threats": 2, "recent_alerts": ["Phishing", "Malware"], "risk_score": 7.5})
