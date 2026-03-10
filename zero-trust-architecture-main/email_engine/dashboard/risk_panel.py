from flask import Blueprint, jsonify

risk_panel = Blueprint('risk_panel', __name__)

@risk_panel.route('/api/risk')
def get_risk():
    return jsonify({"risk_score": 72, "risk_factors": ["IP reputation", "Bounce rate", "User complaints"], "trend": [60, 65, 70, 72]})
