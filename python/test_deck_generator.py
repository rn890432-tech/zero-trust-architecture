import pytest
from alerting_helpers import check_alerts, check_red_button_alerts, check_forecast_alerts

def test_classify_severity():
    task = {"breach_probability": 0.95, "time_to_sla_minutes": 20}
    assert classify_severity(task) == "Critical"

def test_build_red_button_events():
    tasks = [{"task_id":"T1","breach_probability":0.9,"time_to_sla_minutes":25,"owner":"Ops"}]
    escalations = build_red_button_events(tasks)
    assert len(escalations) == 1
    assert escalations[0][2] == "Critical"

def test_check_alerts():
    data = {"metrics": {"sla_compliance": 0.89, "forecasted_breaches": 12}}
    check_alerts(data)
    check_forecast_alerts(data)

def test_check_red_button_alerts():
    escalations = [{}]*6
    check_red_button_alerts(escalations)

if __name__ == "__main__":
    pytest.main()
