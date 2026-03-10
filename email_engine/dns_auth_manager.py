# DNS/Auth Records Manager (SPF, DKIM, DMARC)
import dns.resolver

class DNSAuthManager:
    def __init__(self, domain):
        self.domain = domain

    def check_spf(self):
        try:
            answers = dns.resolver.resolve(f'{self.domain}', 'TXT')
            for rdata in answers:
                if 'v=spf1' in str(rdata):
                    return True
        except Exception:
            return False
        return False

    def check_dkim(self, selector='default'):
        try:
            dkim_domain = f'{selector}._domainkey.{self.domain}'
            answers = dns.resolver.resolve(dkim_domain, 'TXT')
            for rdata in answers:
                if 'v=DKIM1' in str(rdata):
                    return True
        except Exception:
            return False
        return False

    def check_dmarc(self):
        try:
            dmarc_domain = f'_dmarc.{self.domain}'
            answers = dns.resolver.resolve(dmarc_domain, 'TXT')
            for rdata in answers:
                if 'v=DMARC1' in str(rdata):
                    return True
        except Exception:
            return False
        return False

    def compliance_status(self):
        return {
            'SPF': self.check_spf(),
            'DKIM': self.check_dkim(),
            'DMARC': self.check_dmarc()
        }
