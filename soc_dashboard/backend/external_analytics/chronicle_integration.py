import requests
import os

def fetch_chronicle_events():
    chronicle_url = os.getenv('CHRONICLE_API_URL', '')
    chronicle_token = os.getenv('CHRONICLE_API_TOKEN', '')
    if chronicle_url and chronicle_token:
        headers = {'Authorization': f'Bearer {chronicle_token}'}
        resp = requests.get(chronicle_url, headers=headers)
        if resp.status_code == 200:
            return resp.json()
        else:
            print('Chronicle API error:', resp.status_code)
            return []
    else:
        print('Chronicle API not configured.')
        return []
