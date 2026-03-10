# Bounce Processor (SES/Mailgun webhook parsing, suppression updates)
import json

class BounceProcessor:
    def __init__(self, suppression_list_path='suppression_list.json'):
        self.suppression_list_path = suppression_list_path
        self.load_suppression_list()

    def load_suppression_list(self):
        try:
            with open(self.suppression_list_path, 'r') as f:
                self.suppression_list = set(json.load(f))
        except Exception:
            self.suppression_list = set()

    def update_suppression_list(self, email):
        self.suppression_list.add(email)
        with open(self.suppression_list_path, 'w') as f:
            json.dump(list(self.suppression_list), f)

    def process_ses_webhook(self, payload):
        # Example SES bounce webhook
        for record in payload.get('Records', []):
            email = record.get('recipient')
            self.update_suppression_list(email)

    def process_mailgun_webhook(self, payload):
        # Example Mailgun bounce webhook
        for event in payload.get('events', []):
            email = event.get('recipient')
            self.update_suppression_list(email)
