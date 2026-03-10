import requests
import os

def fetch_sentinel_events():
    sentinel_url = os.getenv('SENTINEL_API_URL', '')
    sentinel_token = os.getenv('SENTINEL_API_TOKEN', '')
    if sentinel_url and sentinel_token:
        headers = {'Authorization': f'Bearer {sentinel_token}'}
        resp = requests.get(sentinel_url, headers=headers)
        if resp.status_code == 200:
            return resp.json()
        else:
            print('Sentinel API error:', resp.status_code)
            return []
    else:
        print('Sentinel API not configured.')
        return []
