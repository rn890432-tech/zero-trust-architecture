import time

class IncidentQueue:
    def __init__(self):
        self.queue = []

    def add_incident(self, incident):
        self.queue.append({'incident': incident, 'timestamp': time.time(), 'status': 'new'})

    def update_incident(self, idx, status):
        if 0 <= idx < len(self.queue):
            self.queue[idx]['status'] = status
            return self.queue[idx]
        return None

    def get_queue(self):
        return self.queue

# Example usage:
# queue = IncidentQueue()
# queue.add_incident({'alert': 'Malware detected'})
# queue.update_incident(0, 'investigating')
# print(queue.get_queue())
