from flask import Blueprint, jsonify

predictive_analytics_panel = Blueprint('predictive_analytics_panel', __name__)

@predictive_analytics_panel.route('/api/predictive-analytics')
def get_predictive_analytics():
    return jsonify({"forecast": [1500, 1600, 1700], "confidence": 0.92, "trend": [1200, 1300, 1400, 1500]})
