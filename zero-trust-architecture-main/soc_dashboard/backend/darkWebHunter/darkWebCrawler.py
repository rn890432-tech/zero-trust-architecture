import requests
import stem
import stem.control
from bs4 import BeautifulSoup
import re
import time

TOR_PROXY = "socks5://127.0.0.1:9050"
COMPANY_KEYWORDS = ["yourcompany.com", "employee@yourcompany.com", "10.0.0.", "yourbrand"]

class DarkWebCrawler:
    def __init__(self, sources):
        self.sources = sources
        self.session = requests.Session()
        self.session.proxies = {'http': TOR_PROXY, 'https': TOR_PROXY}

    def crawl(self):
        results = []
        for url in self.sources:
            try:
                resp = self.session.get(url, timeout=30)
                soup = BeautifulSoup(resp.text, 'html.parser')
                posts = soup.find_all('div', class_='post')
                for post in posts:
                    text = post.get_text()
                    if any(kw in text for kw in COMPANY_KEYWORDS):
                        results.append({
                            'source': url,
                            'text': text,
                            'timestamp': time.time()
                        })
            except Exception as e:
                print(f"Error crawling {url}: {e}")
        return results

# Example usage:
# sources = ["http://darkwebforum.onion", "http://leaksite.onion"]
# crawler = DarkWebCrawler(sources)
# posts = crawler.crawl()
