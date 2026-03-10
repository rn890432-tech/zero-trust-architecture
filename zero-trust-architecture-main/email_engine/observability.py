# Observability Stack (Prometheus + Grafana monitoring)
from prometheus_client import start_http_server, Summary, Counter, Gauge
import random
import time

REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request')
EMAIL_SENT = Counter('emails_sent_total', 'Total emails sent')
EMAIL_BOUNCED = Counter('emails_bounced_total', 'Total emails bounced')
EMAIL_OPENED = Counter('emails_opened_total', 'Total emails opened')
EMAIL_CLICKED = Counter('emails_clicked_total', 'Total emails clicked')
QUEUE_LENGTH = Gauge('email_queue_length', 'Current email queue length')

# Example metrics update
@REQUEST_TIME.time()
def process_request():
    time.sleep(random.random())
    EMAIL_SENT.inc()
    EMAIL_OPENED.inc(random.randint(0, 2))
    EMAIL_CLICKED.inc(random.randint(0, 1))
    EMAIL_BOUNCED.inc(random.randint(0, 1))
    QUEUE_LENGTH.set(random.randint(0, 100))

if __name__ == '__main__':
    start_http_server(8000)
    while True:
        process_request()
        time.sleep(5)
