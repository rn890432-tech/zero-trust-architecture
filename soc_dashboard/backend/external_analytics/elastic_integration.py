import requests
import os

def fetch_elastic_events():
    elastic_url = os.getenv('ELASTIC_API_URL', '')
    elastic_token = os.getenv('ELASTIC_API_TOKEN', '')
    if elastic_url and elastic_token:
        headers = {'Authorization': f'Bearer {elastic_token}'}
        resp = requests.get(elastic_url, headers=headers)
        if resp.status_code == 200:
            return resp.json()
        else:
            print('Elastic API error:', resp.status_code)
            return []
    else:
        print('Elastic API not configured.')
        return []
