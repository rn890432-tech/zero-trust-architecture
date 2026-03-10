import requests
import os

def fetch_splunk_events():
    splunk_url = os.getenv('SPLUNK_API_URL', '')
    splunk_token = os.getenv('SPLUNK_API_TOKEN', '')
    if splunk_url and splunk_token:
        headers = {'Authorization': f'Bearer {splunk_token}'}
        resp = requests.get(splunk_url, headers=headers)
        if resp.status_code == 200:
            return resp.json()
        else:
            print('Splunk API error:', resp.status_code)
            return []
    else:
        print('Splunk API not configured.')
        return []
