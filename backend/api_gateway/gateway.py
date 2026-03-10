from fastapi import FastAPI, Depends, HTTPException, Header
import psycopg2
from backend.auth_service.auth import decode_token

app = FastAPI()

def get_current_user(authorization: str = Header(...)):
    if not authorization.startswith('Bearer '):
        raise HTTPException(status_code=401, detail='Invalid token')
    token = authorization.split(' ')[1]
    user = decode_token(token)
    if not user:
        raise HTTPException(status_code=401, detail='Token expired or invalid')
    return user

@app.get("/alerts")
def get_alerts(user=Depends(get_current_user)):
    conn = psycopg2.connect("dbname=soc user=postgres password=postgres host=postgres")
    cur = conn.cursor()
    cur.execute("SELECT * FROM alerts WHERE tenant_id = %s", (user['tenant_id'],))
    alerts = cur.fetchall()
    cur.close()
    conn.close()
    return alerts
