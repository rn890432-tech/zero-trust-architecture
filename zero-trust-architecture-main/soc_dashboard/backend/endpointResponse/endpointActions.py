class EndpointActions:
    def __init__(self):
        self.actions = []

    def quarantine(self, endpoint):
        action = {'endpoint': endpoint, 'action': 'quarantine', 'timestamp': time.time()}
        self.actions.append(action)
        return action

    def disable_user(self, user):
        action = {'user': user, 'action': 'disable', 'timestamp': time.time()}
        self.actions.append(action)
        return action

    def block_domain(self, domain):
        action = {'domain': domain, 'action': 'block', 'timestamp': time.time()}
        self.actions.append(action)
        return action

    def get_actions(self):
        return self.actions

# Example usage:
# actions = EndpointActions()
# actions.quarantine('endpoint1')
# actions.disable_user('user1')
# actions.block_domain('malicious.com')
# print(actions.get_actions())
