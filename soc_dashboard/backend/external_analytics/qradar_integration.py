import requests
import os

def fetch_qradar_events():
    qradar_url = os.getenv('QRADAR_API_URL', '')
    qradar_token = os.getenv('QRADAR_API_TOKEN', '')
    if qradar_url and qradar_token:
        headers = {'Authorization': f'Bearer {qradar_token}'}
        resp = requests.get(qradar_url, headers=headers)
        if resp.status_code == 200:
            return resp.json()
        else:
            print('QRadar API error:', resp.status_code)
            return []
    else:
        print('QRadar API not configured.')
        return []
