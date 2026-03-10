import json
import redis
import time

# Connection to the Redis queue defined in the architecture
redis_client = redis.Redis(host='localhost', port=6379, db=0)

def trigger_test_job(tag, content, latencies, mfa=False):
    job = {
        "data_tag": tag,
        "content": content,
        "to": "target@example.com",
        "subject": f"Security Test: {tag.upper()}",
        "latencies": latencies,
        "baseline": [0.20, 0.21, 0.22, 0.20], # Standard baseline
        "mfa_verified": mfa
    }
    redis_client.lpush("email_queue", json.dumps(job))
    print(f"[TEST] Injected {tag} job into queue.")

if __name__ == "__main__":
    print("🚀 Starting SOC Pipeline Test...\n")

    # 🟢 TEST 1: Standard Communication (Level 1)
    # Expected: Normal processing, low security overhead.
    trigger_test_job("standard_comms", "Hello World", [0.21, 0.22])

    time.sleep(2)

    # 🟡 TEST 2: Business Credentials (Level 2) - ANOMALY SIMULATION
    # Expected: Dashboard Alert. Fisher Engine detects high variance (0.50 vs baseline 0.20).
    trigger_test_job("business_credentials", "user:admin | pass:12345", [0.50, 0.55], mfa=True)

    time.sleep(2)

    # 🔴 TEST 3: Financial Records (Level 3) - MFA FAILURE
    # Expected: Immediate Block. Policy requires MFA; job should be discarded by worker.
    trigger_test_job("financial_records", "Account: 99821-X | Balance: $50,000", [0.20, 0.21], mfa=False)

    print("\n✅ All test jobs injected. Check your SOC Dashboard for pulse alerts.")
