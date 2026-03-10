from flask import Blueprint, jsonify

compliance_trends_panel = Blueprint('compliance_trends_panel', __name__)

@compliance_trends_panel.route('/api/compliance-trends')
def get_compliance_trends():
    return jsonify({"gdpr": ["ok", "ok", "pending"], "ccpa": ["ok", "pending", "ok"], "trend": [98, 97, 99]})
