import pytest
from app import app

@pytest.fixture
def client():
    return app.test_client()

def test_financial_access_no_clearance(client):
    response = client.post('/api/v1/delivery/secure')
    assert response.status_code == 403
    assert b"Insufficient Security Clearance" in response.data

def test_financial_access_no_mfa(client):
    headers = {'X-Security-Clearance': '2'}
    response = client.post('/api/v1/delivery/secure', headers=headers)
    assert response.status_code == 403

def test_successful_level_3_access(client):
    headers = {
        'X-Security-Clearance': '3',
        'X-MFA-Verified': 'true'
    }
    response = client.post('/api/v1/delivery/secure', headers=headers)
    assert response.status_code == 200
