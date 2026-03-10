import json
import requests
import time
import os
from datetime import datetime
import pdfkit
import msal
from google.oauth2 import service_account
from google.auth.transport.requests import Request as GoogleRequest
import smtplib
from email.mime.text import MIMEText
import logging
from fastapi import FastAPI, Request, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import jwt
from fastapi.responses import JSONResponse
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from pydantic import BaseModel, ValidationError

# Feedback model for feedback endpoint
class FeedbackModel(BaseModel):
    feedback: str
    user_id: str
from starlette.requests import Request as StarletteRequest
from starlette.middleware.base import BaseHTTPMiddleware
 # Removed Flask imports

app = FastAPI()
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(429, _rate_limit_exceeded_handler)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Allow CORS for dashboard frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = os.environ.get("DASHBOARD_SECRET", "supersecret")
ALGORITHM = "HS256"

# Root endpoint for health check
@app.get("/")
def root():
    return {"status": "Dashboard API is running"}
# Dummy user validation (replace with real user DB)
def verify_token(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/api/submit_feedback")
@limiter.limit("10/minute")
def api_submit_feedback(request: Request, feedback: FeedbackModel, user: str = Depends(verify_token)):
    try:
        feedback_dict = feedback.dict()
        backend_submit_feedback(feedback_dict)
        return {"status": "success"}
    except ValidationError as e:
        return JSONResponse(status_code=400, content={"error": str(e)})

@app.get("/api/fetch_feedback")
def api_fetch_feedback(user: str = Depends(verify_token)):
    return backend_fetch_feedback()

@app.post("/api/retrain_model")
def api_retrain_model(feedback: list, user: str = Depends(verify_token)):
    backend_retrain_model(feedback)
    return {"status": "retrained"}

@app.get("/api/insights")
def api_insights(user: str = Depends(verify_token)):
    return backend_fetch_insights()

@app.get("/api/live_accuracy")
def api_live_accuracy(user: str = Depends(verify_token)):
    return {"accuracy": get_live_accuracy()}

@app.get("/api/audit_trail")
def api_audit_trail(user: str = Depends(verify_token)):
    # Return last 100 audit events
    return backend_fetch_audit_trail(limit=100)

@app.post("/block-domain")
async def block_domain(request: Request):
    data = await request.json()
    domain = data.get('domain')
    # Integration point for Firewall API (e.g., Palo Alto, Fortinet, or Cloudflare)
    print(f"Executing Block Rule for: {domain}")
    return {"status": "success"}

def generate_incident_report(analysis_results):
    report = f"""
    === PHISHING INCIDENT REPORT ===
    Status: THREAT NEUTRALIZED
    URL Analyzed: {analysis_results['url']}
    Risk Score: {analysis_results['risk_level']}
    
    Technical Indicators:
    - {chr(10).join(analysis_results['findings'])}
    
    Vigilance Note: Employee followed the 'Golden Rule' and aborted the session.
    Recommended Action: Block domain at the firewall level.
    ================================
    """
    return report

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)