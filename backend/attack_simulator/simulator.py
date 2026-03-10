import random
import time
from datetime import datetime

ATTACK_TYPES = [
    "login_brute_force",
    "phishing_email",
    "malware_beacon",
    "lateral_movement"
]

ASSETS = ["web_server", "database", "user_account", "mail_server", "vpn_gateway"]
SEVERITY_RANGE = [1, 2, 3, 4, 5]


def random_ip():
    return ".".join(str(random.randint(1, 254)) for _ in range(4))


def simulate_attack_event():
    event = {
        "timestamp": datetime.utcnow().isoformat(),
        "attack_type": random.choice(ATTACK_TYPES),
        "source_ip": random_ip(),
        "target_asset": random.choice(ASSETS),
        "severity": random.choice(SEVERITY_RANGE)
    }
    return event


def main():
    while True:
        event = simulate_attack_event()
        print(event)
        time.sleep(random.uniform(0.5, 2))

if __name__ == "__main__":
    main()
