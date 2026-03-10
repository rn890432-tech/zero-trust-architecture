from functools import wraps
from flask import request, abort
import yaml
import os

# Load policies from config.yml
CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'config.yml')
with open(CONFIG_PATH, 'r') as f:
    config = yaml.safe_load(f)

def require_clearance(data_type):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # 1. Fetch policy for the specific data type
            policy = config['data_classification'].get(data_type)
            if not policy:
                abort(400, description="Unknown data type policy")
            # 2. Validate Header
            user_clearance = int(request.headers.get('X-Security-Clearance', 0))
            if user_clearance < policy['clearance_level']:
                abort(403, description="Insufficient Security Clearance")
            # 3. Verify MFA if required
            if policy.get('mfa_required') and not request.headers.get('X-MFA-Verified'):
                abort(401, description="MFA Verification Required for Level 3")
            return f(*args, **kwargs)
        return decorated_function
    return decorator
