import requests

def fetch_external_threat_feed():
    response = requests.get('https://threatfeed.example.com/api/latest')
    if response.status_code == 200:
        return response.json()
    return []
