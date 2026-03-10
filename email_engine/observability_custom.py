# Custom Prometheus Metrics for Deliverability, Latency, Queue Health
from prometheus_client import Gauge, Counter

DELIVERABILITY_SCORE = Gauge('deliverability_score', 'Current deliverability score')
EMAIL_LATENCY = Gauge('email_latency_seconds', 'Average email send latency (seconds)')
QUEUE_HEALTH = Gauge('queue_health', 'Queue health score')

# Example metric updates
DELIVERABILITY_SCORE.set(0.98)
EMAIL_LATENCY.set(1.2)
QUEUE_HEALTH.set(95)
