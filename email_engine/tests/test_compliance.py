# Unit tests for compliance modules
import unittest
from email_engine.unsubscribe_manager import UnsubscribeManager
from email_engine.compliance_suppression_db import ComplianceSuppressionDB
from email_engine.rate_limiter import RateLimiter
from email_engine.ip_warmup import IPWarmup

class TestCompliance(unittest.TestCase):
    def test_unsubscribe_manager(self):
        um = UnsubscribeManager()
        um.unsubscribe('user@test.com')
        self.assertTrue(um.is_unsubscribed('user@test.com'))

    def test_compliance_db(self):
        db = ComplianceSuppressionDB()
        db.add('suppressed@test.com', 'bounce')
        self.assertTrue(db.is_suppressed('suppressed@test.com'))

    def test_rate_limiter(self):
        rl = RateLimiter(per_minute=2)
        self.assertTrue(rl.can_send('user@test.com'))
        rl.record_send('user@test.com')
        rl.record_send('user@test.com')
        self.assertFalse(rl.can_send('user@test.com'))

    def test_ip_warmup(self):
        iw = IPWarmup(100, days=5)
        self.assertEqual(len(iw.schedule), 5)

if __name__ == '__main__':
    unittest.main()
