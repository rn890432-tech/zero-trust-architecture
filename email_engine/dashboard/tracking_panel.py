# Tracking Metrics Panel API
from flask import Blueprint, jsonify
from email_engine.tracking import Tracking

tracking_panel = Blueprint('tracking_panel', __name__)

@tracking_panel.route('/api/tracking_metrics')
def tracking_metrics():
    tr = Tracking()
    open_count = sum(1 for e in tr.db.values() if e['type'] == 'open')
    click_count = sum(1 for e in tr.db.values() if e['type'] == 'click')
    return jsonify({'open_count': open_count, 'click_count': click_count})
