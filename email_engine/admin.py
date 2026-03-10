# Admin Controls (multi-tenant, API keys, webhooks, RBAC)
import json
import uuid

class AdminManager:
    def __init__(self, db_path='admin_db.json'):
        self.db_path = db_path
        self.load_db()

    def load_db(self):
        try:
            with open(self.db_path, 'r') as f:
                self.db = json.load(f)
        except Exception:
            self.db = {}

    def create_tenant(self, name):
        tenant_id = str(uuid.uuid4())
        self.db[tenant_id] = {'name': name, 'api_keys': [], 'webhooks': [], 'roles': {}}
        self.save_db()
        return tenant_id

    def add_api_key(self, tenant_id, key):
        self.db[tenant_id]['api_keys'].append(key)
        self.save_db()

    def add_webhook(self, tenant_id, url):
        self.db[tenant_id]['webhooks'].append(url)
        self.save_db()

    def set_role(self, tenant_id, user, role):
        self.db[tenant_id]['roles'][user] = role
        self.save_db()

    def save_db(self):
        with open(self.db_path, 'w') as f:
            json.dump(self.db, f)
