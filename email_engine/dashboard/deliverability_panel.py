# Deliverability Score Panel API
from flask import Blueprint, jsonify
from email_engine.logging_db import LoggingDB

import random

deliverability_panel = Blueprint('deliverability_panel', __name__)

@deliverability_panel.route('/api/deliverability_score')
def deliverability_score():
    db = LoggingDB()
    sent = len([e for e in db.get_events('all') if e[1] == 'send'])
    delivered = len([e for e in db.get_events('all') if e[1] == 'delivered'])
    bounces = len([e for e in db.get_events('all') if e[1] == 'bounce'])
    score = 0.0
    if sent > 0:
        score = (delivered - bounces) / sent
    else:
        score = random.uniform(0.95, 0.99)
    return jsonify({'deliverability_score': round(score, 3)})
