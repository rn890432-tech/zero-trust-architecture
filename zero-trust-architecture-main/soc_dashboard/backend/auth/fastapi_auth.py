from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from passlib.context import CryptContext
import jwt
import time
import psycopg2

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"

class User(BaseModel):
    username: str
    password: str
    role: str
    org: str
    disabled: bool = False

# PostgreSQL connection (simplified)
def get_db():
    return psycopg2.connect(dbname="soc_users", user="admin", password="password", host="localhost")

def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

def get_user(username):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT username, password, role, org, disabled FROM users WHERE username=%s", (username,))
    row = cur.fetchone()
    conn.close()
    if row:
        return User(username=row[0], password=row[1], role=row[2], org=row[3], disabled=row[4])
    return None

def authenticate_user(username, password):
    user = get_user(username)
    if not user or not verify_password(password, user.password):
        return None
    return user

def create_access_token(data, expires_delta=None):
    to_encode = data.copy()
    expire = time.time() + (expires_delta or 3600)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

@app.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    access_token = create_access_token({"sub": user.username, "role": user.role, "org": user.org})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me")
def read_users_me(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user = get_user(payload["sub"])
        if user.disabled:
            raise HTTPException(status_code=400, detail="Inactive user")
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

# User management endpoints (create, disable, assign roles)
@app.post("/users/create")
def create_user(user: User):
    conn = get_db()
    cur = conn.cursor()
    hashed = pwd_context.hash(user.password)
    cur.execute("INSERT INTO users (username, password, role, org, disabled) VALUES (%s, %s, %s, %s, %s)", (user.username, hashed, user.role, user.org, user.disabled))
    conn.commit()
    conn.close()
    return {"status": "created"}

@app.post("/users/disable")
def disable_user(username: str):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("UPDATE users SET disabled=true WHERE username=%s", (username,))
    conn.commit()
    conn.close()
    return {"status": "disabled"}

@app.post("/users/assign_role")
def assign_role(username: str, role: str):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("UPDATE users SET role=%s WHERE username=%s", (role, username))
    conn.commit()
    conn.close()
    return {"status": "role updated"}

# Rate limiting, session expiration, audit logging, and multi-tenant support would be expanded here.
