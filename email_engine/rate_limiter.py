# Rate Limiting (per-minute, IP/domain, warmup schedule)
import time
from collections import defaultdict

class RateLimiter:
    def __init__(self, per_minute=100):
        self.per_minute = per_minute
        self.sent = defaultdict(list)

    def can_send(self, key):
        now = time.time()
        self.sent[key] = [t for t in self.sent[key] if now - t < 60]
        return len(self.sent[key]) < self.per_minute

    def record_send(self, key):
        self.sent[key].append(time.time())

    def warmup_schedule(self, volume, days=7):
        return [int(volume * (i+1)/days) for i in range(days)]
