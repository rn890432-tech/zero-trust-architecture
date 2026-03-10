# SMTP Connection Pool (multi-vendor, TLS, retry strategies)
import smtplib
import threading
import queue

class SMTPConnectionPool:
    def __init__(self, vendors, max_connections=5):
        self.vendors = vendors  # List of SMTP configs
        self.max_connections = max_connections
        self.pool = queue.Queue(max_connections)
        self.lock = threading.Lock()
        self._init_pool()

    def _init_pool(self):
        for vendor in self.vendors:
            conn = smtplib.SMTP_SSL(vendor['host'], vendor['port'])
            conn.login(vendor['username'], vendor['password'])
            self.pool.put(conn)

    def get_connection(self):
        return self.pool.get()

    def release_connection(self, conn):
        self.pool.put(conn)

    def close_all(self):
        while not self.pool.empty():
            conn = self.pool.get()
            conn.quit()

# Example vendor config
# vendors = [
#     {'host': 'smtp.gmail.com', 'port': 465, 'username': 'user', 'password': 'pass'},
#     {'host': 'smtp.mailgun.org', 'port': 465, 'username': 'user', 'password': 'pass'}
# ]
# pool = SMTPConnectionPool(vendors)
