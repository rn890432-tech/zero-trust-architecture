import requests

def query_endpoint_status(endpoint_id):
    import os
    EDR_URL = os.getenv('EDR_URL', 'https://edr.example.com/api/endpoints')
    try:
        resp = requests.get(f'{EDR_URL}/{endpoint_id}/status', timeout=5)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print('Failed to query endpoint:', e)
        return {'endpoint_id': endpoint_id, 'status': 'unknown'}

def isolate_endpoint(endpoint_id):
    import os
    EDR_URL = os.getenv('EDR_URL', 'https://edr.example.com/api/endpoints')
    try:
        resp = requests.post(f'{EDR_URL}/{endpoint_id}/isolate', timeout=5)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print('Failed to isolate endpoint:', e)
        return {'endpoint_id': endpoint_id, 'result': 'failed'}

def remediate_endpoint(endpoint_id):
    import os
    EDR_URL = os.getenv('EDR_URL', 'https://edr.example.com/api/endpoints')
    try:
        resp = requests.post(f'{EDR_URL}/{endpoint_id}/remediate', timeout=5)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print('Failed to remediate endpoint:', e)
        return {'endpoint_id': endpoint_id, 'result': 'failed'}
