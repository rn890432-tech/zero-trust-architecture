# Unsubscribe Management (one-click, global, per-topic, auto footer)
import json

class UnsubscribeManager:
    def __init__(self, db_path='unsubscribe_db.json'):
        self.db_path = db_path
        self.load_db()

    def load_db(self):
        try:
            with open(self.db_path, 'r') as f:
                self.db = json.load(f)
        except Exception:
            self.db = {}

    def unsubscribe(self, email, topic=None):
        if topic:
            self.db.setdefault(email, {'global': False, 'topics': []})
            if topic not in self.db[email]['topics']:
                self.db[email]['topics'].append(topic)
        else:
            self.db[email] = {'global': True, 'topics': []}
        self.save_db()

    def is_unsubscribed(self, email, topic=None):
        entry = self.db.get(email, {'global': False, 'topics': []})
        if entry['global']:
            return True
        if topic and topic in entry['topics']:
            return True
        return False

    def save_db(self):
        with open(self.db_path, 'w') as f:
            json.dump(self.db, f)

    def add_footer(self, email_body):
        footer = '\n\nTo unsubscribe, click here.'
        return email_body + footer
