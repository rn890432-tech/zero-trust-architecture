# Zero Trust Automation PowerShell Scripts — Security Audit Trail

**Last Audit:** 2026-02-25

---

## Credential Handling Compliance

All scripts in this repository have been reviewed and refactored to ensure:
- No plain text secrets (passwords, tokens, connection strings, API keys) are stored in code, variables, or files.
- All sensitive credentials are handled using `[SecureString]` and/or `PSCredential`.
- Where persistent secrets are needed, Windows Credential Manager is supported.

---

## Script-by-Script Credential Handling

### Environment & Core Automation
- **set_zt_env_vars.ps1**: SecureString for ServiceNow password; never stored as plain text.
- **automate_report_and_email.ps1**: All credentials (ServiceNow, email) use SecureString.
- **create_servicenow_incident.ps1**: Accepts only SecureString for ServiceNow password.

### Email & Notification
- **test-email.ps1**: Prompts for SMTP password as SecureString.
- **automation_notify.ps1**: Prompts for SMTP and Twilio credentials as SecureString.
- **send-custom-email.ps1**: Uses SecureString or Credential Manager for email credentials.

### Issue & Incident Management
- **create_jira_issue.ps1**: Prompts for Jira API token as SecureString.
- **create_github_issue.ps1**: Prompts for GitHub token as SecureString.

### Integration Scripts (SecureString Compliant)
- **send_to_splunk.ps1**: Splunk HEC token accepted as SecureString.
- **send_pagerduty_alert.ps1**: PagerDuty Routing Key accepted as SecureString.
- **upload_to_azure_blob.ps1**: Azure connection string accepted as SecureString.
- **upload_to_s3.ps1**: AWS access/secret keys can be passed as SecureString.

### Additional Scripts
- **set_globals.ps1** / **temp_prompt_and_run.ps1**: Email passwords are prompted as SecureString at runtime.
- **Other scripts**: No credential handling detected; no action required.

---

## Ongoing Compliance

- All new scripts must use SecureString or PSCredential for sensitive credentials.
- No secrets should be stored in plain text or files.
- Use Windows Credential Manager for persistent secrets where possible.
- This audit trail should be updated after any script or credential-handling change.

---

## Last Full Audit
- All scripts reviewed and secured as of 2026-02-25.
- No plain text secrets remain in any script or file.
- All credential handling is compliant with PowerShell security best practices.

---

*For questions or to trigger a new compliance check, contact your automation administrator or run the compliance audit workflow.*
