from threatActorDB import get_actors

class ThreatAttributionEngine:
    def __init__(self):
        self.actors = get_actors()

    def attribute(self, indicators, techniques, malware):
        scores = []
        for actor in self.actors:
            score = 0
            if any(ip in actor['ips'] for ip in indicators.get('ips', [])):
                score += 30
            if any(domain in actor['domains'] for domain in indicators.get('domains', [])):
                score += 20
            if any(m in actor['malware'] for m in malware):
                score += 20
            if any(t in actor['techniques'] for t in techniques):
                score += 20
            scores.append({
                'actor': actor['name'],
                'score': score,
                'campaigns': actor.get('malware', []),
                'techniques': actor.get('techniques', []),
                'infrastructure': actor.get('ips', []) + actor.get('domains', [])
            })
        scores.sort(key=lambda x: x['score'], reverse=True)
        return scores[0] if scores else None

# Example usage:
# engine = ThreatAttributionEngine()
# result = engine.attribute({'ips': ['185.22.10.5']}, ['lateral_movement'], ['DarkHydra'])
