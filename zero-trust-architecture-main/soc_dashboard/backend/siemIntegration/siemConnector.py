class SIEMConnector:
    def __init__(self):
        self.events = []

    def send_event(self, event):
        # Placeholder: send event to SIEM
        self.events.append(event)

    def get_events(self):
        return self.events

# Example usage:
# connector = SIEMConnector()
# connector.send_event({'alert': 'Malware detected'})
# print(connector.get_events())
