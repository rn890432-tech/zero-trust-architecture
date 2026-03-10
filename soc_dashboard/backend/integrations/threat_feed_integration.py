import requests

def fetch_threat_feed():
    import os, time
    FEED_URL = os.getenv('THREAT_FEED_URL', 'https://threatfeed.example.com/api/latest')
    try:
        resp = requests.get(FEED_URL, timeout=10)
        resp.raise_for_status()
        feed = resp.json()
        # Deduplicate by indicator
        seen = set()
        unique = []
        for item in feed:
            ind = item.get('indicator')
            if ind and ind not in seen:
                seen.add(ind)
                unique.append(item)
        return unique
    except Exception as e:
        print('Failed to fetch threat feed:', e)
        return []
