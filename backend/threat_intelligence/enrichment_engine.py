def enrich_alert(alert, feeds):
    reputation = {}
    if alert.get("source_ip") in feeds.get("malicious_ips", []):
        reputation["ip_reputation"] = "malicious"
    if alert.get("domain") in feeds.get("phishing_domains", []):
        reputation["domain_reputation"] = "phishing"
    if alert.get("hash") in feeds.get("malware_hashes", []):
        reputation["hash_reputation"] = "malware"
    alert["reputation"] = reputation
    return alert

if __name__ == "__main__":
    sample_alert = {"source_ip": "192.168.1.10", "domain": "badsite.com", "hash": "abcd1234"}
    feeds = {
        "malicious_ips": ["192.168.1.10"],
        "phishing_domains": ["badsite.com"],
        "malware_hashes": ["abcd1234"]
    }
    enriched = enrich_alert(sample_alert, feeds)
    print(enriched)
