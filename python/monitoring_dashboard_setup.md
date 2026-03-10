# Monitoring Dashboard Setup (Cloud Monitoring)

1. **Log-based Metrics**
   - In Cloud Logging, create log-based metrics for:
     - `deck_generated` events
     - `red_button_escalation` (escalation count)
     - `sla_trend` (SLA compliance trend)
     - `forecasted_breaches` (forecasted breach count)

2. **Dashboards**
   - In Cloud Monitoring, create a dashboard with:
     - Deck Runs per Week (log-based metric)
     - Red Button Escalations (log-based metric)
     - SLA Compliance Trend (log-based metric)
     - Forecasted Breaches (log-based metric)

3. **Widgets**
   - Add time series widgets for each metric.
   - Add threshold/alert widgets for escalation count and SLA compliance.

4. **Alerts**
   - Set alerts for:
     - No deck run in last 7 days
     - >5 Red Button escalations in a week
     - SLA compliance <90%
     - Forecasted breaches >10
   - Alerts can be sent to Slack/Teams using webhook integrations.

5. **Grafana-style Views**
   - Use Cloud Monitoring widgets to visualize trends and alert counts for leadership.

6. **Custom Widgets**
   - Escalation Severity Distribution: Pie chart widget showing counts of Critical, High, Medium, Low from log-based metric `escalation_severity_distribution`.
   - Deck Run Duration: Time series widget showing deck generation duration (seconds) from log-based metric `deck_run_duration`.

7. **Additional Widgets**
   - Deck Error Count: Bar chart widget showing deck error occurrences from log-based metric `deck_error_count`.
   - Weekly Deck Run Success Rate: Gauge or line chart widget showing deck run success rate from log-based metric `weekly_deck_run_success_rate`.

8. **Advanced Widgets**
   - Chart Rendering Latency: Line chart widget showing chart rendering time (seconds) from log-based metric `chart_rendering_latency`.
   - Alert Delivery Count: Stacked bar chart widget showing alert delivery counts by alert_type from log-based metric `alert_delivery_count`.

9. **Example Visualization**
   - Pie chart for escalation severity: Filter logs by event_type="escalation_severity_distribution" and plot severity_counts.
   - Line chart for deck run duration: Filter logs by event_type="deck_run_duration" and plot duration over time.
   - Bar chart for deck error count: Filter logs by event_type="deck_error_count" and plot count per week.
   - Gauge/line chart for weekly deck run success rate: Filter logs by event_type="weekly_deck_run_success_rate" and plot rate over time.
   - Line chart for chart rendering latency: Filter logs by event_type="chart_rendering_latency" and plot seconds over time.
   - Stacked bar chart for alert delivery count: Filter logs by event_type="alert_delivery_count" and plot count by alert_type per week.
