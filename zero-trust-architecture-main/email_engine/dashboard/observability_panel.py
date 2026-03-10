from flask import Blueprint, jsonify

observability_panel = Blueprint('observability_panel', __name__)

@observability_panel.route('/api/observability')
def get_observability():
    return jsonify({"uptime": "99.98%", "latency_ms": 120, "errors": 2})
