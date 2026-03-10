class AlertRulesEngine:
    def __init__(self):
        self.rules = []
        self.alerts = []

    def add_rule(self, rule):
        self.rules.append(rule)

    def evaluate(self, event):
        for rule in self.rules:
            if rule['condition'](event):
                self.alerts.append({'event': event, 'rule': rule['name'], 'timestamp': event['timestamp']})

    def get_alerts(self):
        return self.alerts

# Example usage:
# engine = AlertRulesEngine()
# engine.add_rule({'name': 'High Risk Login', 'condition': lambda e: e['risk'] > 80})
# engine.evaluate({'user': 'alice', 'risk': 90, 'timestamp': time.time()})
# print(engine.get_alerts())
