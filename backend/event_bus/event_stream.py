import redis
import json
import time

r = redis.Redis(host='localhost', port=6379, db=0)
CHANNEL = 'soc_events'

def publish_event(event):
    r.publish(CHANNEL, json.dumps(event))

def subscribe_events():
    pubsub = r.pubsub()
    pubsub.subscribe(CHANNEL)
    for message in pubsub.listen():
        if message['type'] == 'message':
            print(json.loads(message['data']))

def main():
    # Example: publish random event
    event = {"type": "test", "data": "hello"}
    publish_event(event)
    subscribe_events()

if __name__ == "__main__":
    main()
