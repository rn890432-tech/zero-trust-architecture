from darkWebCrawler import DarkWebCrawler
from nlpEngine import NLPEngine
from threatScoring import score_threat

class DarkWebPipeline:
    def __init__(self, sources):
        self.crawler = DarkWebCrawler(sources)
        self.nlp = NLPEngine()

    def run(self):
        posts = self.crawler.crawl()
        results = []
        for post in posts:
            indicators = self.nlp.analyze(post['text'])
            threat = score_threat(indicators)
            results.append({
                'source': post['source'],
                'text': post['text'],
                'timestamp': post['timestamp'],
                'indicators': indicators,
                'threat': threat
            })
        return results

# Example usage:
# pipeline = DarkWebPipeline(["http://darkwebforum.onion"])
# threats = pipeline.run()
