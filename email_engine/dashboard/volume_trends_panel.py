from flask import Blueprint, jsonify

volume_trends_panel = Blueprint('volume_trends_panel', __name__)

@volume_trends_panel.route('/api/volume-trends')
def get_volume_trends():
    return jsonify({"daily": [1200, 1300, 1100, 1400, 1500], "weekly": [8000, 8200, 7900], "monthly": [32000, 33000]})
