from alerting_helpers import check_alerts, check_red_button_alerts, check_forecast_alerts

def test_check_alerts():
    data = {"metrics": {"sla_compliance": 0.89, "forecasted_breaches": 12}}
    check_alerts(data)
    check_forecast_alerts(data)

def test_check_red_button_alerts():
    escalations = [{}]*6
    check_red_button_alerts(escalations)

if __name__ == "__main__":
    test_check_alerts()
    test_check_red_button_alerts()
