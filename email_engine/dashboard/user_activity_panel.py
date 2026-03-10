from flask import Blueprint, jsonify

user_activity_panel = Blueprint('user_activity_panel', __name__)

@user_activity_panel.route('/api/user-activity')
def get_user_activity():
    return jsonify({"active_users": 12, "recent_actions": ["Login", "Report download", "Alert acknowledged"], "activity_trend": [5, 8, 12]})
