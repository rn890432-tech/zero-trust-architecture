# Queue Health Panel API
from flask import Blueprint, jsonify
import redis

queue_panel = Blueprint('queue_panel', __name__)

@queue_panel.route('/api/queue_health')
def queue_health():
    try:
        r = redis.Redis.from_url('redis://localhost:6379/0')
        queue_length = r.zcard('retry_queue')
        dead_letter_length = r.llen('dead_letter_queue')
        return jsonify({'queue_length': queue_length, 'dead_letter_length': dead_letter_length})
    except Exception:
        return jsonify({'queue_length': 0, 'dead_letter_length': 0})
