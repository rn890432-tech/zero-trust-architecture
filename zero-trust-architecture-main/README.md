# Zero Trust Architecture Demo

This project demonstrates a Zero Trust security architecture using Bash scripts and supporting files.

## Key Features

- Secure business intake
- Admin search and audit
- Data archiving
- Digital signing (GPG)

## Usage

Run the main script:

```bash
bash zero-trust-policy.sh
```

All data and logs are stored in this directory.

---

## Notification Script Environment Variables

The PowerShell notification script (`automation_notify.ps1`) requires the following environment variables for secure operation:

|Variable Name|Description|Example Value|
|---|---|---|
|`ZTA_EMAIL_USER`|Sender email address (Gmail recommended)|`your@email.com`|
|`ZTA_EMAIL_PASS`|App password for sender email|`your-app-password`|
|`ZTA_EMAIL_TO`|Recipient email address|`recipient@email.com`|
|`ZTA_SLACK_WEBHOOK`|Slack webhook URL for notifications|`https://hooks.slack.com/services/...`|

### How to Set Environment Variables (PowerShell)

Run these commands in a PowerShell terminal (replace with your actual values):

```powershell
[System.Environment]::SetEnvironmentVariable("ZTA_EMAIL_USER", "your@email.com", "User")
[System.Environment]::SetEnvironmentVariable("ZTA_EMAIL_PASS", "your-app-password", "User")
[System.Environment]::SetEnvironmentVariable("ZTA_EMAIL_TO", "recipient@email.com", "User")
[System.Environment]::SetEnvironmentVariable("ZTA_SLACK_WEBHOOK", "https://hooks.slack.com/services/XXX/YYY/ZZZ", "User")
```

Restart your PowerShell session or log out/in for changes to take effect.

---

# SOC Artifact Dashboard Deployment & Enhancement Guide

## Deployment Steps

1. **Install Python & Dependencies**
   - Ensure Python 3.8+ is installed.
   - Install required package:
     ```sh
     pip install requests
     ```

2. **Prepare Artifact Data**
   - Place your SOC artifact data in `artifact_log.json` (or configure API endpoint).

3. **Run Automation Script**
   - Generate/update dashboard:
     ```sh
     python automate_dashboard_report.py --user socadmin --password secure2026
     ```
   - For scheduled automation:
     ```sh
     python automate_dashboard_report.py --interval 60
     ```

4. **Open Dashboard**
   - Open `soc_dashboard.html` in your browser.
   - Dashboard auto-loads data and provides interactive features.

5. **Integrate with Splunk/ELK/Custom Web Apps**
   - Export artifact data as JSON from your platform.
   - Place/export as `artifact_log.json` or provide API endpoint.
   - See `dashboard_integration_guide.md` for details.

## Additional Features & Integration Help

### OAuth Authentication
- Dashboard and automation script include placeholders for OAuth integration.
- Replace demo login with enterprise OAuth (Azure AD, Google, Okta, etc.).
- See comments in `soc_dashboard.html` and `automate_dashboard_report.py` for integration points.

### Real-Time Updates
- Dashboard auto-refreshes data every 60 seconds (AJAX polling).
- For live data, point to an API endpoint or update polling interval as needed.

### Advanced Analytics
- Dashboard includes a pie chart for artifact type distribution (Chart.js).
- Automation script detects anomalies in artifact types and prints results.
- Extend analytics in both files for more insights (trend analysis, alerting, etc.).

### Integration & Customization
- For OAuth, update integration points in both files with your provider's flow.
- For real-time data, connect dashboard to your API or SIEM platform.
- For advanced analytics, add custom logic in Python and JS as needed.
- For help, see comments and guides in the code and [dashboard_integration_guide.md](dashboard_integration_guide.md).

## Google OAuth2 Authentication
- Automation script supports Google OAuth2 login (see `automate_dashboard_report.py`).
  - Use `google_oauth2_authenticate(service_account.json, scopes)` to get access token.
  - Example usage provided in script comments.

## More Analytics
- Automation script analyzes artifact anomaly trends and source correlation.
- Extend analytics for deeper insights (multi-source, anomaly, time series, correlation).

## Extended Automation
- Use `automate_dashboard_refresh_extended(sources, interval_minutes, email_config)` for multi-source pulls, dashboard/report refresh, email notification, and error logging.
- Example email configuration provided in script comments.
- Errors are logged to `automation_errors.log`.

## Direct Integration with Splunk/ELK APIs
- Automation script includes functions to fetch data from Splunk and ELK APIs.
- Example usage:
  ```python
  splunk_results = fetch_splunk_data('https://splunk.example.com/services/search/jobs/export', 'YOUR_SPLUNK_TOKEN', 'search index=main | head 100')
  elk_results = fetch_elk_data('https://elk.example.com:9200', 'artifacts', {"match_all": {}})
  ```
- Use results as artifact data for dashboard and reporting.
- Update API URLs, tokens, and queries for your environment.

## Azure AD & Okta OAuth Authentication
- Dashboard supports Azure AD login (see `soc_dashboard.html`).
  - Replace `YOUR_AZURE_AD_CLIENT_ID` with your Azure AD client ID.
  - Users log in with Azure AD; username is shown on successful authentication.
- Automation script includes Okta OAuth integration placeholder.
  - Integrate with Okta SDK or API for enterprise login.

## More Analytics
- Dashboard shows pie chart (type), line chart (trend), bar chart (source), and heatmap placeholder.
- Automation script prints artifact trend, source distribution, and heatmap placeholder.
- Extend analytics for more insights (correlation, anomaly, time-based heatmaps, etc.).

## Splunk/ELK Integration Help
- Use `fetch_splunk_data()` and `fetch_elk_data()` in automation script for direct API integration.
- Pass results to analytics and dashboard for real-time reporting.
- Update API endpoints, tokens, and queries for your environment.
- For advanced integration, automate data pulls and dashboard refreshes.

## Generic OAuth2 Provider Authentication
- Dashboard supports custom OAuth2 login (see `soc_dashboard.html`).
  - Update authorization endpoint and client ID for your provider.
  - Users log in with your enterprise OAuth2 provider.
- Automation script includes generic OAuth2 integration placeholder.
  - Integrate with your provider's API for backend authentication.

## Advanced Analytics
- Dashboard shows correlation scatter plot (type vs source), time-based heatmap placeholder, and all previous charts.
- Automation script prints correlation analysis and time-based heatmap placeholder.
- Extend analytics for deeper insights (multi-dimensional, anomaly, time series, etc.).

## Deeper SIEM Integration Help
- For Splunk, use advanced queries, schedule data pulls, and automate dashboard refresh.
- For ELK, use custom queries, automate index monitoring, and push updates to dashboard.
- For other SIEMs, implement similar API fetch and analytics logic.
- Extend automation script and dashboard for real-time, multi-source analytics.

## Further Enhancements

- **Advanced Authentication**
  - Replace demo login with OAuth, SSO, or enterprise authentication.

- **Real-Time Data Updates**
  - Add WebSocket or periodic AJAX polling in `soc_dashboard.html` for live updates.

- **Custom Analytics**
  - Extend `renderAnalytics()` in dashboard for more charts (pie, line, heatmap).
  - Add anomaly detection, trend analysis, or alerting in Python script.

- **Export & Sharing**
  - Add export options (PDF, CSV) to dashboard.
  - Integrate email or Slack notifications in automation script.

- **UI/UX Improvements**
  - Add more filters, sorting, and responsive design tweaks.
  - Enhance modals with remediation actions or evidence links.

- **Security & Compliance**
  - Harden authentication and data access.
  - Add audit logging and access controls.

## Support & Customization

- For platform-specific integration, see [dashboard_integration_guide.md](dashboard_integration_guide.md).
- For custom features, modify `soc_dashboard.html` (UI/JS) and `automate_dashboard_report.py` (backend/automation).

---

For questions or further customization, contact your SOC engineering team or request additional features here.

## Microsoft Azure AD OAuth2 Authentication
- Automation script supports Azure AD OAuth2 login (see `automate_dashboard_report.py`).
  - Use `azure_ad_authenticate(client_id, tenant_id, client_secret)` to get access token.
  - Example usage provided in script comments.

## Custom Analytics
- Automation script compares artifact counts across multiple sources (Splunk, ELK, JSON, etc.).
- Extend `compare_sources_analytics()` for deeper insights (correlation, anomaly, time series).

## Automated Multi-Source Data Pulls & Dashboard Refresh
- Use `automate_dashboard_refresh(sources, interval_minutes)` to pull data from multiple sources and refresh dashboard/report on a schedule.
- Example source configuration provided in script comments.
- Dashboard and PDF report are updated automatically after each pull.

## Okta OAuth2 Authentication
- Automation script supports Okta OAuth2 login (see `automate_dashboard_report.py`).
  - Use `okta_oauth2_authenticate(client_id, client_secret, okta_domain)` to get access token.
  - Example usage provided in script comments.

## Auth0 OAuth2 Authentication
- Automation script supports Auth0 OAuth2 login (see `automate_dashboard_report.py`).
  - Use `auth0_oauth2_authenticate(client_id, client_secret, domain)` to get access token.
  - Example usage provided in script comments.

## More Analytics
- Automation script analyzes artifact type/source ratio and top N sources.
- Extend analytics for deeper insights (multi-source, anomaly, time series, correlation).

## Additional Automation Features
- Use `send_teams_notification(message, webhook_url)` to notify Microsoft Teams channels of updates.
- Use `export_csv(artifacts, output_path)` to export artifacts to CSV.
- Use `scheduled_cleanup(file_paths)` to remove old files on a schedule.
- Example usage provided in script comments.

## Backend Integration
- Automation script supports backend integration for integrity monitor and escalation workflow (see `automate_dashboard_report.py`).
  - Use `backend_log_audit_event(event_type, details, api_url, token)` to log audit events to backend.
  - Use `backend_escalation_event(level, details, api_url, token)` to log escalation events to backend.
  - Use `backend_rule_rollback(api_url, token)` to trigger rule rollback on backend.
  - Example usage provided in script comments.

## Backend API Integration for Policy Management
- Automation script supports backend API integration for escalation policy management (see `automate_dashboard_report.py`).
  - Use `backend_get_escalation_policies(api_url, token)` to fetch escalation policies from backend.
  - Use `backend_save_escalation_policies(policies, api_url, token)` to save policies to backend.
  - Use `backend_log_policy_change(change_details, api_url, token)` to log policy changes to backend.
  - Use `apply_escalation_policy(level, policies, api_url, token)` to apply policies dynamically with backend actions (rollback, lock, etc.).
  - Example usage provided in script comments.

## Backend Simulation Endpoints
- Automation script supports backend simulation endpoints for escalation policy testing (see `automate_dashboard_report.py`).
  - Use `backend_simulate_escalation_policy(level, policies, api_url, token)` to simulate escalation policy for a given tampering level.
  - Use `batch_policy_simulation(levels, policies, api_url, token)` to run batch simulations for multiple levels.
  - Use `scheduled_policy_test(policies, api_url, token, interval_minutes)` to automate scheduled policy simulation tests and reporting.
  - Example usage provided in script comments.

## Further Workflow Automation
- Automate policy simulation, escalation testing, and reporting via backend endpoints and scheduled tasks.
- Extend automation for enterprise compliance, audit, and governance workflows.

---

For further customization, request code for specific backend endpoints, advanced workflow logic, or integration with SIEM/ITSM platforms.
# zero-trust-architecture
#   z e r o - t r u s t - a r c h i t e c t u r e  
 #   z e r o - t r u s t - a r c h i t e c t u r e - m a i n - a l l  
 