# SOC Alerting Dashboard UI Wireframes

## Main Views
- Analyst View: Real-time event stream, queue depth, worker health, drill-down, retry controls
- Executive View: Summary metrics, SLA compliance, system health, delivery stats
- Provider Status Panel: SMTP provider health, failover history, latency, error rates

## Components
- Event Timeline (chart)
- Queue Depth (gauge)
- Worker Health (table)
- Delivery Metrics (opens/clicks/bounces chart)
- Provider Health (status cards)
- Alerts Panel (severity, timestamp, description)
- Search/Filter Bar
- Role-based Access Controls (login, permissions)

## Wireframe Sketch
```
+-------------------------------------------------------------+
| SOC Alerting Dashboard                                      |
+-------------------------------------------------------------+
| [NavBar] [Search/Filter] [Role Selector]                    |
+-------------------------------------------------------------+
| [Event Timeline]   [Queue Depth Gauge]   [Worker Health]    |
| [Delivery Metrics] [Provider Health]    [Alerts Panel]      |
+-------------------------------------------------------------+
| [Drill-down/Details]                                        |
+-------------------------------------------------------------+
```
