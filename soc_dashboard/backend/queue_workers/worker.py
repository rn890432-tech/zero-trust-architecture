import time

def worker():
    # Consume from queue, process, retry, dead-letter
    while True:
        # Placeholder: fetch message from Kafka/Redis
        msg = None
        if msg:
            # Process message
            pass
        time.sleep(1)

if __name__ == '__main__':
    worker()
