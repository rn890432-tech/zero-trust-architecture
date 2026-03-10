# Tracking (open pixel, click redirector, device + geo metrics)
import uuid
import datetime

class Tracking:
    def __init__(self, db_path='tracking_events.json'):
        self.db_path = db_path
        self.load_db()

    def load_db(self):
        try:
            import json
            with open(self.db_path, 'r') as f:
                self.db = json.load(f)
        except Exception:
            self.db = {}

    def log_event(self, event_type, email, meta=None):
        event_id = str(uuid.uuid4())
        event = {
            'id': event_id,
            'type': event_type,
            'email': email,
            'timestamp': datetime.datetime.now().isoformat(),
            'meta': meta or {}
        }
        self.db[event_id] = event
        self.save_db()
        return event_id

    def save_db(self):
        import json
        with open(self.db_path, 'w') as f:
            json.dump(self.db, f)

    def generate_open_pixel(self, email):
        pixel_id = self.log_event('open', email)
        return f'<img src="https://yourdomain.com/track/open/{pixel_id}" width="1" height="1" />'

    def generate_click_redirect(self, email, url):
        click_id = self.log_event('click', email, {'url': url})
        return f'https://yourdomain.com/track/click/{click_id}'
