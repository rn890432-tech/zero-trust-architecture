from flask import Blueprint, jsonify

compliance_panel = Blueprint('compliance_panel', __name__)

@compliance_panel.route('/api/compliance')
def get_compliance():
    return jsonify({"gdpr": "ok", "ccpa": "ok", "hipaa": "pending", "last_audit": "2026-02-20"})
