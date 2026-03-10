def get_plan_features(plan):
    if plan == "free":
        return {"max_users": 5, "ai_analyst": False}
    elif plan == "pro":
        return {"max_users": 100, "ai_analyst": True, "threat_hunting": True}
    elif plan == "enterprise":
        return {"max_users": 1000, "ai_analyst": True, "threat_hunting": True, "soar": True}
    return {}
