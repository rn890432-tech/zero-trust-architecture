import unittest
import requests

class TestSOCMicroservices(unittest.TestCase):
    def test_threat_intel(self):
        resp = requests.get('http://localhost:5001/threat-intel')
        self.assertEqual(resp.status_code, 200)
    def test_attack_graph(self):
        resp = requests.get('http://localhost:5002/attack-graph')
        self.assertEqual(resp.status_code, 200)
    def test_autonomous_defense(self):
        resp = requests.post('http://localhost:5003/autonomous-defense')
        self.assertEqual(resp.status_code, 200)
    def test_dark_web_hunting(self):
        resp = requests.get('http://localhost:5004/dark-web-hunting')
        self.assertEqual(resp.status_code, 200)
    def test_threat_actor_attribution(self):
        resp = requests.get('http://localhost:5005/threat-actor-attribution')
        self.assertEqual(resp.status_code, 200)
    def test_threat_hunting_ai(self):
        resp = requests.post('http://localhost:5006/threat-hunting-ai')
        self.assertEqual(resp.status_code, 200)

if __name__ == '__main__':
    unittest.main()
