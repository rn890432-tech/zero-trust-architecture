import time

class CaseManager:
    def __init__(self):
        self.cases = []
        self.activities = []

    def create_case(self, alert, analyst):
        case = {
            'id': len(self.cases) + 1,
            'alert': alert,
            'analyst': analyst,
            'status': 'open',
            'created': time.time(),
            'actions': []
        }
        self.cases.append(case)
        return case

    def update_case(self, case_id, action):
        for case in self.cases:
            if case['id'] == case_id:
                case['actions'].append({'action': action, 'timestamp': time.time()})
                return case
        return None

    def close_case(self, case_id):
        for case in self.cases:
            if case['id'] == case_id:
                case['status'] = 'closed'
                return case
        return None

    def get_cases(self):
        return self.cases

    def log_activity(self, analyst, activity):
        self.activities.append({'analyst': analyst, 'activity': activity, 'timestamp': time.time()})

    def get_activities(self):
        return self.activities

# Example usage:
# manager = CaseManager()
# case = manager.create_case({'alert': 'Suspicious login'}, 'analyst1')
# manager.update_case(case['id'], 'Investigated login')
# manager.close_case(case['id'])
# print(manager.get_cases())
# manager.log_activity('analyst1', 'Closed case')
# print(manager.get_activities())
