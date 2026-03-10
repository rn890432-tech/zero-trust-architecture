from flask import Blueprint, jsonify

workflow_panel = Blueprint('workflow_panel', __name__)

@workflow_panel.route('/api/workflow')
def get_workflow():
    return jsonify({"automation_status": "active", "last_run": "2026-03-07", "tasks": ["Send report", "Archive logs", "Notify team"]})
