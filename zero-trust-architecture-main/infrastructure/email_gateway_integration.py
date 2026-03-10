import requests

def block_domain(domain):
    response = requests.post('https://emailgateway.example.com/api/block', json={'domain': domain})
    return response.status_code

def unblock_domain(domain):
    response = requests.post('https://emailgateway.example.com/api/unblock', json={'domain': domain})
    return response.status_code
