import random
import time

MITRE_TECHNIQUES = [
    "phishing", "credential_access", "ransomware", "privilege_escalation", "lateral_movement", "data_exfiltration"
]

ATTACK_SCENARIOS = [
    {"name": "Phishing Email Compromise", "techniques": ["phishing", "credential_access"]},
    {"name": "Ransomware Deployment", "techniques": ["ransomware", "data_exfiltration"]},
    {"name": "Privilege Escalation", "techniques": ["privilege_escalation", "lateral_movement"]},
    {"name": "Lateral Movement", "techniques": ["lateral_movement", "data_exfiltration"]}
]

class RedTeamSimulator:
    def __init__(self):
        self.active_attacks = []
        self.results = []

    def simulate_attack(self):
        scenario = random.choice(ATTACK_SCENARIOS)
        attack_path = []
        for tech in scenario["techniques"]:
            attack_path.append({
                "technique": tech,
                "timestamp": time.time() + random.randint(1, 10)
            })
        attack = {
            "scenario": scenario["name"],
            "path": attack_path,
            "detected": random.choice([True, False]),
            "response_time": random.randint(10, 120),
            "ai_accuracy": random.uniform(0.7, 1.0)
        }
        self.active_attacks.append(attack)
        self.results.append(attack)
        return attack

    def get_active_attacks(self):
        return self.active_attacks

    def get_results(self):
        return self.results

# Example usage:
# simulator = RedTeamSimulator()
# attack = simulator.simulate_attack()
# print(simulator.get_active_attacks())
# print(simulator.get_results())
