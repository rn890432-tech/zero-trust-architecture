import requests

def send_to_siem(event):
    import os
    SIEM_URL = os.getenv('SIEM_URL', 'https://siem.example.com/api/events')
    SIEM_API_KEY = os.getenv('SIEM_API_KEY', 'changeme')
    headers = {'Authorization': f'Bearer {SIEM_API_KEY}', 'Content-Type': 'application/json'}
    try:
        resp = requests.post(SIEM_URL, json=event, headers=headers, timeout=5)
        resp.raise_for_status()
        print('Event sent to SIEM:', event)
    except Exception as e:
        print('Failed to send event to SIEM:', e)
