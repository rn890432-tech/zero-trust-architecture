from flask import Blueprint, jsonify

device_analytics_panel = Blueprint('device_analytics_panel', __name__)

@device_analytics_panel.route('/api/device-analytics')
def get_device_analytics():
    return jsonify({"devices": {"mobile": 800, "desktop": 600}, "trend": [700, 800, 900, 800, 600]})
