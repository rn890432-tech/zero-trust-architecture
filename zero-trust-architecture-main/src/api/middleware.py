from functools import wraps
from flask import request, abort
import yaml

# Load policies from config.yml
with open("config.yml", "r") as f:
    config = yaml.safe_load(f)

def require_clearance(data_type):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            policy = config['data_classification'].get(data_type)
            user_clearance = int(request.headers.get('X-Security-Clearance', 0))
            if user_clearance < policy['clearance_level']:
                abort(403, description="Insufficient Security Clearance")
            if policy['mfa_required'] and not request.headers.get('X-MFA-Verified'):
                abort(401, description="MFA Verification Required for Level 3")
            return f(*args, **kwargs)
        return decorated_function
    return decorator
