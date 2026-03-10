from flask import Blueprint, jsonify

external_integration_panel = Blueprint('external_integration_panel', __name__)

@external_integration_panel.route('/api/external-integration')
def get_external_integration():
    return jsonify({"services": ["Slack", "ServiceNow", "Azure"], "last_sync": "2026-03-07", "status": "connected"})
