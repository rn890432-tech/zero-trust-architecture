# Suppression List Panel API
from flask import Blueprint, jsonify
from email_engine.compliance_suppression_db import ComplianceSuppressionDB

suppression_panel = Blueprint('suppression_panel', __name__)

@suppression_panel.route('/api/suppression_list')
def suppression_list():
    db = ComplianceSuppressionDB()
    return jsonify(db.db)
