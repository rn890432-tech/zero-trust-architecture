# Unit tests for core modules
import unittest
from unittest.mock import patch, MagicMock
from email_engine.smtp_pool import SMTPConnectionPool
from email_engine.retry_queue import RetryQueue
from email_engine.bounce_processor import BounceProcessor
from email_engine.logging_db import LoggingDB

class TestCore(unittest.TestCase):
    @patch('smtplib.SMTP_SSL')
    def test_smtp_pool(self, mock_smtp):
        mock_conn = MagicMock()
        mock_smtp.return_value = mock_conn
        vendors = [{'host': 'smtp.test.com', 'port': 465, 'username': 'u', 'password': 'p'}]
        pool = SMTPConnectionPool(vendors)
        conn = pool.get_connection()
        pool.release_connection(conn)
        pool.close_all()
        self.assertTrue(True)

    @patch('redis.Redis')
    def test_retry_queue(self, mock_redis):
        mock_r = MagicMock()
        mock_redis.from_url.return_value = mock_r
        mock_r.zadd.return_value = None
        mock_r.zrange.return_value = [b'{"email": "a@test.com"}']
        mock_r.zrem.return_value = None
        rq = RetryQueue()
        rq.enqueue({'email': 'a@test.com'}, priority=1)
        task = rq.dequeue()
        self.assertIsNotNone(task)

    def test_bounce_processor(self):
        bp = BounceProcessor()
        bp.update_suppression_list('bounced@test.com')
        self.assertIn('bounced@test.com', bp.suppression_list)

    def test_logging_db(self):
        db = LoggingDB()
        db.log_event('send', 'c@test.com')
        events = db.get_events('c@test.com')
        self.assertTrue(len(events) > 0)

if __name__ == '__main__':
    unittest.main()
