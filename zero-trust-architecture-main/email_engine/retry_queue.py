# Retry Queue (exponential backoff, dead letter, Redis priority)
import redis
import time
import json

class RetryQueue:
    def __init__(self, redis_url='redis://localhost:6379/0'):
        self.r = redis.Redis.from_url(redis_url)

    def enqueue(self, task, priority=1):
        self.r.zadd('retry_queue', {json.dumps(task): priority})

    def dequeue(self):
        items = self.r.zrange('retry_queue', 0, 0)
        if items:
            task = json.loads(items[0])
            self.r.zrem('retry_queue', items[0])
            return task
        return None

    def dead_letter(self, task):
        self.r.lpush('dead_letter_queue', json.dumps(task))

    def exponential_backoff(self, attempt):
        return min(60, 2 ** attempt)
