# Authentication service for SaaS SOC
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from .models import User, Tenant
from .jwt_auth import create_access_token

app = FastAPI()

@app.post('/login')
def login(email: str, password: str, db: Session):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail='Invalid credentials')
    token = create_access_token({
        'user_id': user.id,
        'tenant_id': user.tenant_id,
        'role': user.role
    })
    return {'access_token': token, 'tenant_id': user.tenant_id, 'role': user.role}

# Add signup, password hashing, and other endpoints as needed
