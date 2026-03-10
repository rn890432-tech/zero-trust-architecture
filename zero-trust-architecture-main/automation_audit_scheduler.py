import schedule
import time
import requests
from datetime import datetime

def run_monthly_audit():
    # Trigger audit export endpoint
    resp = requests.post('http://localhost:5000/api/v1/audit/export', headers={
        'X-Security-Clearance': '3',
        'X-MFA-Verified': 'true'
    })
    print(f"[{datetime.now()}] Monthly Audit Export Triggered: {resp.json()}")

schedule.every().month.at("09:00").do(run_monthly_audit)

print("Audit scheduler started. Waiting for next run...")
while True:
    schedule.run_pending()
    time.sleep(60)
