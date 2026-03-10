def score_threat(indicators):
    score = 0
    if indicators['emails']:
        score += 30
    if indicators['domains']:
        score += 20
    if indicators['ips']:
        score += 20
    if indicators['passwords']:
        score += 40
    if indicators['keywords']:
        score += 10 * len(indicators['keywords'])
    if score >= 80:
        severity = 'Critical'
    elif score >= 60:
        severity = 'High'
    elif score >= 40:
        severity = 'Medium'
    else:
        severity = 'Low'
    return {'score': score, 'severity': severity}

# Example usage:
# threat = score_threat(indicators)
