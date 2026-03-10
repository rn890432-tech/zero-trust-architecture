import jwt
import datetime

SECRET_KEY = 'supersecret'

def generate_jwt(payload):
    payload['exp'] = datetime.datetime.utcnow() + datetime.timedelta(hours=12)
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def decode_jwt(token):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
    except jwt.ExpiredSignatureError:
        return None
