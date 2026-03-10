import requests

def quarantine_endpoint(endpoint_id):
    response = requests.post('https://endpoint.example.com/api/quarantine', json={'id': endpoint_id})
    return response.status_code

def release_endpoint(endpoint_id):
    response = requests.post('https://endpoint.example.com/api/release', json={'id': endpoint_id})
    return response.status_code
