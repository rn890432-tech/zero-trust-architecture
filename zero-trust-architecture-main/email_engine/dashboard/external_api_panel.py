from flask import Blueprint, jsonify

external_api_panel = Blueprint('external_api_panel', __name__)

@external_api_panel.route('/api/external-api')
def get_external_api():
    return jsonify({"apis": ["Slack", "ServiceNow", "Azure"], "status": "connected", "last_sync": "2026-03-07"})
