import requests

def block_ip(ip):
    # Example: call firewall API to block IP
    response = requests.post('https://firewall.example.com/api/block', json={'ip': ip})
    return response.status_code

def unblock_ip(ip):
    response = requests.post('https://firewall.example.com/api/unblock', json={'ip': ip})
    return response.status_code
