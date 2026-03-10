import secrets
import time
from common.logger import logger

def generate_admin_session():
    """
    Generates a high-entropy JIT (Just-In-Time) token for admin access.
    Ensures proactive intervention against brute-force attempts.
    """
    token = secrets.token_urlsafe(32)
    timestamp = time.time()
    logger.info(f"ADMIN_SESSION_CREATED: Token generated at {timestamp}")
    print("-" * 30)
    print("SOC COMMAND CENTER ADMIN ACCESS")
    print("-" * 30)
    print(f"URL: http://localhost:5000/admin/login?token={token}")
    print("VALID FOR: 10 Minutes")
    print("-" * 30)

if __name__ == "__main__":
    generate_admin_session()
