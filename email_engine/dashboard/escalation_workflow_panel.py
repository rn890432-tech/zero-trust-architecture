from flask import Blueprint, jsonify

escalation_workflow_panel = Blueprint('escalation_workflow_panel', __name__)

@escalation_workflow_panel.route('/api/escalation-workflow')
def get_escalation_workflow():
    return jsonify({"status": "active", "steps": ["Detect incident", "Notify team", "Escalate to management"], "last_escalation": "2026-03-07"})
