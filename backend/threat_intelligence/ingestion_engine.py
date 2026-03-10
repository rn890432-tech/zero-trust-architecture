import requests

def fetch_malicious_ips():
    # Placeholder: Replace with real feed URL
    return ["192.168.1.10", "10.0.0.5"]

def fetch_phishing_domains():
    return ["badsite.com", "phishme.net"]

def fetch_malware_hashes():
    return ["abcd1234", "deadbeef"]

def ingest_feeds():
    return {
        "malicious_ips": fetch_malicious_ips(),
        "phishing_domains": fetch_phishing_domains(),
        "malware_hashes": fetch_malware_hashes()
    }

if __name__ == "__main__":
    feeds = ingest_feeds()
    print(feeds)
