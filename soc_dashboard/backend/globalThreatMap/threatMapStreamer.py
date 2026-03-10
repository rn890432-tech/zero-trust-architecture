import random
import time

COUNTRIES = ["US", "RU", "CN", "DE", "FR", "BR", "IN", "GB", "JP", "KR"]
THREAT_TYPES = ["phishing", "malware", "botnet", "ransomware"]

class ThreatMapStreamer:
    def __init__(self):
        self.attacks = []

    def stream_attack(self):
        attack = {
            "source": random.choice(COUNTRIES),
            "target": random.choice(COUNTRIES),
            "type": random.choice(THREAT_TYPES),
            "timestamp": time.time(),
            "source_ip": f"{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}",
            "target_ip": f"{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}"
        }
        self.attacks.append(attack)
        return attack

    def get_attacks(self):
        return self.attacks

# Example usage:
# streamer = ThreatMapStreamer()
# for _ in range(10):
#   streamer.stream_attack()
# print(streamer.get_attacks())
