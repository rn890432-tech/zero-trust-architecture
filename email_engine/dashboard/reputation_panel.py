from flask import Blueprint, jsonify

reputation_panel = Blueprint('reputation_panel', __name__)

@reputation_panel.route('/api/reputation')
def get_reputation():
    return jsonify({"score": 92, "blacklists": ["none"], "recent_issues": 1})
