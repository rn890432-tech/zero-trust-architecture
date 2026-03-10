# Compliance Suppression DB (bounces, complaints, removals, temp failures)
import json

class ComplianceSuppressionDB:
    def __init__(self, db_path='compliance_suppression.json'):
        self.db_path = db_path
        self.load_db()

    def load_db(self):
        try:
            with open(self.db_path, 'r') as f:
                self.db = json.load(f)
        except Exception:
            self.db = {}

    def add(self, email, reason):
        self.db[email] = reason
        self.save_db()

    def is_suppressed(self, email):
        return email in self.db

    def save_db(self):
        with open(self.db_path, 'w') as f:
            json.dump(self.db, f)
