from flask import Blueprint, jsonify
import statistics

sla_panel = Blueprint('sla_panel', __name__)

resolution_times = [120, 90, 150, 110, 100]

@sla_panel.route('/api/sla')
def get_sla():
    median_time = statistics.median(resolution_times)
    return jsonify({"median_resolution_time": median_time, "sla_target": 100, "breaches": 1})
