# SOC Artifact Dashboard Integration Guide

This guide explains how to integrate the interactive dashboard with Splunk, ELK, and custom web apps, and how to automate report generation and analytics.

## 1. Dashboard Overview
- **File:** soc_dashboard.html
- **Features:**
  - Interactive filtering, searching, and sorting
  - Color-coded summary charts
  - Modal details
  - Dark mode toggle
  - Authentication (demo)
  - Analytics panel

## 2. Automation Script
- **File:** automate_dashboard_report.py
- **Usage:**
  - Run once: `python automate_dashboard_report.py --user socadmin --password secure2026`
  - Schedule: `python automate_dashboard_report.py --interval 60` (runs every 60 minutes)
  - Supports artifact data from local JSON or API endpoint

## 3. Integration with Splunk
- Export artifact data from Splunk as JSON (search > export > JSON)
- Place exported file as `artifact_log.json` in the workspace
- Dashboard will auto-load and visualize the data
- For real-time integration, set up a Splunk REST API endpoint and pass `--api <url>` to the automation script

## 4. Integration with ELK (Elasticsearch, Logstash, Kibana)
- Export relevant data from Kibana/Elasticsearch as JSON
- Place as `artifact_log.json` or use API endpoint
- Dashboard and automation script will process and visualize
- For scheduled updates, use the automation script with interval

## 5. Integration with Custom Web Apps
- Ensure artifact data is available as JSON (file or API)
- Update dashboard or script to point to your data source
- Extend dashboard JS to support custom fields if needed

## 6. Authentication
- Simple demo authentication in dashboard and script (username: socadmin, password: secure2026)
- For production, replace with secure authentication (OAuth, SSO, etc.)

## 7. Additional Analytics Features
- Artifact type distribution
- Source breakdown
- Add more analytics in `renderAnalytics()` in soc_dashboard.html
- Extend Python script for custom analytics and reporting

## 8. Customization
- Modify soc_dashboard.html for UI/UX changes
- Extend automate_dashboard_report.py for advanced automation, notifications, or integrations

## 9. Troubleshooting
- Ensure `artifact_log.json` is present and valid
- Install Python dependencies: `pip install requests`
- Check browser console for JS errors
- Review script output for authentication or data issues

---
For further enhancements, add advanced analytics, export options, or integrate with SIEM APIs as needed.