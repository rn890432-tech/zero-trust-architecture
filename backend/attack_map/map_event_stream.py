import json
import random
import time
import websocket

# Placeholder for geolocation lookup
COUNTRIES = ["US", "UK", "RU", "BR", "CN", "EU"]


def random_coords():
    return {
        "lat": round(random.uniform(-90, 90), 2),
        "lon": round(random.uniform(-180, 180), 2)
    }

def generate_attack_line():
    return {
        "source": random_coords(),
        "target": random_coords(),
        "country_from": random.choice(COUNTRIES),
        "country_to": random.choice(COUNTRIES)
    }

def stream_attack_events():
    ws = websocket.create_connection("ws://localhost:8765")
    while True:
        event = generate_attack_line()
        ws.send(json.dumps(event))
        time.sleep(random.uniform(0.5, 2))

if __name__ == "__main__":
    stream_attack_events()
