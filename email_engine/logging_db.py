# Logging DB (send attempts, deliveries, opens, clicks, bounces, unsubscribes)
import sqlite3
import datetime

class LoggingDB:
    def __init__(self, db_path='email_logs.db'):
        self.conn = sqlite3.connect(db_path)
        self.create_tables()

    def create_tables(self):
        c = self.conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT,
            email TEXT,
            timestamp TEXT,
            meta TEXT
        )''')
        self.conn.commit()

    def log_event(self, event_type, email, meta=None):
        c = self.conn.cursor()
        c.execute('INSERT INTO logs (event_type, email, timestamp, meta) VALUES (?, ?, ?, ?)',
                  (event_type, email, datetime.datetime.now().isoformat(), json.dumps(meta) if meta else None))
        self.conn.commit()

    def get_events(self, email):
        c = self.conn.cursor()
        c.execute('SELECT * FROM logs WHERE email=?', (email,))
        return c.fetchall()
