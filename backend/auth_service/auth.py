import jwt
import datetime

SECRET_KEY = 'supersecret'


def generate_token(user_id, tenant_id, role):
    payload = {
        'user_id': user_id,
        'tenant_id': tenant_id,
        'role': role,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=12)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')


def decode_token(token):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
    except jwt.ExpiredSignatureError:
        return None
