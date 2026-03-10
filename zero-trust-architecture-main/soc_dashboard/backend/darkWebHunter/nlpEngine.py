import re

COMPANY_KEYWORDS = ["yourcompany.com", "employee@yourcompany.com", "10.0.0.", "yourbrand"]

EMAIL_REGEX = r"[\w\.-]+@[\w\.-]+"
DOMAIN_REGEX = r"[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
IP_REGEX = r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b"
PASSWORD_REGEX = r"password: ([^\s]+)"

class NLPEngine:
    def analyze(self, post):
        indicators = {}
        indicators['emails'] = re.findall(EMAIL_REGEX, post)
        indicators['domains'] = re.findall(DOMAIN_REGEX, post)
        indicators['ips'] = re.findall(IP_REGEX, post)
        indicators['passwords'] = re.findall(PASSWORD_REGEX, post)
        indicators['keywords'] = [kw for kw in COMPANY_KEYWORDS if kw in post]
        return indicators

# Example usage:
# nlp = NLPEngine()
# indicators = nlp.analyze(post)
