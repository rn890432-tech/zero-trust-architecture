import time

class ReportingEngine:
    def __init__(self):
        self.reports = []

    def generate_report(self, incidents, cases):
        report = {
            'timestamp': time.time(),
            'incidents': len(incidents),
            'cases': len(cases),
            'details': {'incidents': incidents, 'cases': cases}
        }
        self.reports.append(report)
        return report

    def get_reports(self):
        return self.reports

# Example usage:
# engine = ReportingEngine()
# report = engine.generate_report([{'id': 1}], [{'id': 1}])
# print(engine.get_reports())
