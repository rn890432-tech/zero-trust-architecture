# Unit tests for tracking and admin modules
import unittest
from email_engine.tracking import Tracking
from email_engine.admin import AdminManager

class TestTrackingAdmin(unittest.TestCase):
    def test_tracking(self):
        tr = Tracking()
        pixel = tr.generate_open_pixel('user@test.com')
        self.assertIn('<img', pixel)
        click_url = tr.generate_click_redirect('user@test.com', 'http://example.com')
        self.assertIn('track/click', click_url)

    def test_admin_manager(self):
        am = AdminManager()
        tid = am.create_tenant('TenantA')
        am.add_api_key(tid, 'key123')
        am.add_webhook(tid, 'http://webhook.com')
        am.set_role(tid, 'user1', 'admin')
        self.assertIn('key123', am.db[tid]['api_keys'])
        self.assertIn('http://webhook.com', am.db[tid]['webhooks'])
        self.assertEqual(am.db[tid]['roles']['user1'], 'admin')

if __name__ == '__main__':
    unittest.main()
