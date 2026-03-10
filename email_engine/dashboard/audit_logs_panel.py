from flask import Blueprint, jsonify

audit_logs_panel = Blueprint('audit_logs_panel', __name__)

@audit_logs_panel.route('/api/audit-logs')
def get_audit_logs():
    return jsonify({"logs": [
        {"user": "Alice", "action": "Login", "timestamp": "2026-03-07"},
        {"user": "Bob", "action": "Report download", "timestamp": "2026-03-07"}
    ]})
