$contactsHeaders2 = @{Authorization = "Bearer $jwt"; "X-Contact-Role" = "admin"}
$deploymentsHeaders2 = @{Authorization = "Bearer $jwt"; "X-Deployment-Mode" = "manual"}
$emailRecipientsHeaders2 = @{Authorization = "Bearer $jwt"; "X-Email-Type" = "alert"}

$contactsPayload2 = '{"contact_id":"cont-002","name":"John Smith","role":"Admin","email":"john.smith@example.com","phone":"+1122334455"}'
$deploymentsPayload2 = '{"deployment_id":"dep-003","service":"database","version":"v5.1","deployed_on":"2026-03-07T05:00:00Z","status":"manual"}'
$emailRecipientsPayload2 = '{"recipient_id":"rec-002","email":"alert@example.com","type":"alert","subscribed":false}'
# More endpoint tests
Test-Endpoint "Admin Contact" "$baseUrl/api/admin_contact" "Post" $contactsHeaders2 $contactsPayload2
Test-Endpoint "Manual Deployment" "$baseUrl/api/manual_deployment" "Post" $deploymentsHeaders2 $deploymentsPayload2
Test-Endpoint "Alert Email Recipient" "$baseUrl/api/alert_email_recipient" "Post" $emailRecipientsHeaders2 $emailRecipientsPayload2
$complianceHeaders2 = @{Authorization = "Bearer $jwt"; "X-Compliance-Check" = "ISO"}
$warningHeaders2 = @{Authorization = "Bearer $jwt"; "X-Warning-Level" = "high"}
$criticalIssueHeaders2 = @{Authorization = "Bearer $jwt"; "X-Critical-Issue" = "urgent"}

$compliancePayload2 = '{"compliance_id":"comp-002","standard":"ISO27001","status":"pending","checked_on":"2026-03-07T04:00:00Z","checked_by":"auditor2"}'
$warningPayload2 = '{"warning_id":"warn-002","message":"High CPU usage","severity":"high","timestamp":"2026-03-07T04:00:00Z","affected_component":"compute_node"}'
$criticalIssuePayload2 = '{"issue_id":"crit-002","title":"Memory leak","description":"Detected in API service","severity":"urgent","reported_on":"2026-03-07T04:00:00Z","status":"open"}'
# More endpoint tests
Test-Endpoint "Compliance Check ISO" "$baseUrl/api/compliance_check_iso" "Post" $complianceHeaders2 $compliancePayload2
Test-Endpoint "High Warning" "$baseUrl/api/high_warning" "Post" $warningHeaders2 $warningPayload2
Test-Endpoint "Urgent Critical Issue" "$baseUrl/api/urgent_critical_issue" "Post" $criticalIssueHeaders2 $criticalIssuePayload2
$feedbackHeaders2 = @{Authorization = "Bearer $jwt"; "X-Feedback-Mode" = "extended"}
$archiveHeaders2 = @{Authorization = "Bearer $jwt"; "X-Archive-Mode" = "daily"}
$deploymentHeaders = @{Authorization = "Bearer $jwt"; "X-Deployment-Type" = "auto"}

$feedbackPayload2 = '{"feedback_id":"fbk-002","feedback":"Extended feedback","user_id":"user888","rating":3,"details":"Additional feedback for testing.","timestamp":"2026-03-07T03:00:00Z"}'
$archivePayload2 = '{"archive_id":"arch-004","type":"daily","files":["report1.pdf","report2.pdf"],"archived_by":"admin006","timestamp":"2026-03-07T03:00:00Z"}'
$deploymentPayload = '{"deployment_id":"dep-002","service":"webapp","version":"v4.0","deployed_by":"devops_team","timestamp":"2026-03-07T03:00:00Z"}'
# More endpoint tests
Test-Endpoint "Submit Feedback Extended" "$baseUrl/api/submit_feedback_extended" "Post" $feedbackHeaders2 $feedbackPayload2
Test-Endpoint "Daily Archive" "$baseUrl/api/daily_archive" "Post" $archiveHeaders2 $archivePayload2
Test-Endpoint "Auto Deployment" "$baseUrl/api/auto_deployment" "Post" $deploymentHeaders $deploymentPayload
$auditTrailHeaders = @{Authorization = "Bearer $jwt"; "X-Audit-Trail" = "full"}
$insightsHeaders = @{Authorization = "Bearer $jwt"; "X-Insights-Mode" = "deep"}
$accuracyHeaders = @{Authorization = "Bearer $jwt"; "X-Accuracy-Check" = "true"}

$auditTrailPayload = '{"audit_id":"aud-001","scope":"full","requested_by":"admin005","timestamp":"2026-03-07T02:00:00Z"}'
$insightsPayload = '{"insight_id":"ins-001","type":"deep","generated_by":"analytics_bot","timestamp":"2026-03-07T02:00:00Z"}'
$accuracyPayload = '{"accuracy_id":"acc-001","model":"v3.0","value":98.7,"checked_by":"qa_team","timestamp":"2026-03-07T02:00:00Z"}'
# More endpoint tests
Test-Endpoint "Audit Trail" "$baseUrl/api/audit_trail" "Post" $auditTrailHeaders $auditTrailPayload
Test-Endpoint "Insights" "$baseUrl/api/insights" "Post" $insightsHeaders $insightsPayload
Test-Endpoint "Live Accuracy" "$baseUrl/api/live_accuracy" "Post" $accuracyHeaders $accuracyPayload
$alertHeaders = @{Authorization = "Bearer $jwt"; "X-Alert-Type" = "critical"}
$domainBlockHeaders = @{Authorization = "Bearer $jwt"; "X-Domain-Block" = "true"}
$userActivityHeaders = @{Authorization = "Bearer $jwt"; "X-User-Activity" = "track"}

$alertPayload = '{"alert_id":"alt-001","type":"critical","message":"Intrusion detected","triggered_by":"monitor_bot","timestamp":"2026-03-07T01:00:00Z"}'
$domainBlockPayload = '{"domain":"malicious.com","reason":"phishing","blocked_by":"sec_team","timestamp":"2026-03-07T01:00:00Z"}'
$userActivityPayload = '{"activity_id":"act-001","user_id":"user999","action":"login","ip":"10.0.0.1","timestamp":"2026-03-07T01:00:00Z"}'
# More endpoint tests
Test-Endpoint "Send Alert" "$baseUrl/api/send_alert" "Post" $alertHeaders $alertPayload
Test-Endpoint "Block Domain" "$baseUrl/api/block_domain" "Post" $domainBlockHeaders $domainBlockPayload
Test-Endpoint "Track User Activity" "$baseUrl/api/track_user_activity" "Post" $userActivityHeaders $userActivityPayload
$backupHeaders = @{Authorization = "Bearer $jwt"; "X-Backup-Request" = "true"}
$restoreHeaders = @{Authorization = "Bearer $jwt"; "X-Restore-Request" = "true"}
$policyHeaders = @{Authorization = "Bearer $jwt"; "X-Policy-Update" = "critical"}

$backupPayload = '{"backup_id":"bkp-001","type":"full","initiated_by":"admin004","timestamp":"2026-03-07T00:00:00Z"}'
$restorePayload = '{"restore_id":"rst-001","type":"incremental","restored_by":"ops_team","timestamp":"2026-03-07T00:00:00Z"}'
$policyPayload = '{"policy_id":"pol-001","type":"security","level":"critical","updated_by":"sec_team","timestamp":"2026-03-07T00:00:00Z"}'
# More endpoint tests
Test-Endpoint "Backup Request" "$baseUrl/api/backup_request" "Post" $backupHeaders $backupPayload
Test-Endpoint "Restore Request" "$baseUrl/api/restore_request" "Post" $restoreHeaders $restorePayload
Test-Endpoint "Policy Update" "$baseUrl/api/policy_update" "Post" $policyHeaders $policyPayload
$settingsHeaders = @{Authorization = "Bearer $jwt"; "X-Settings-Update" = "true"}
$userExportHeaders = @{Authorization = "Bearer $jwt"; "X-Export-User" = "all"}
$incidentArchiveHeaders = @{Authorization = "Bearer $jwt"; "X-Incident-Archive" = "true"}

$settingsPayload = '{"settings_id":"set-001","changes":{"theme":"dark","notifications":false},"updated_by":"admin003","timestamp":"2026-03-06T23:00:00Z"}'
$userExportPayload = '{"export_id":"exp-002","type":"user","count":50,"requested_by":"ops_team","timestamp":"2026-03-06T23:00:00Z"}'
$incidentArchivePayload = '{"archive_id":"inc-003","type":"incident","incidents":["inc-001","inc-002"],"archived_by":"qa_team","timestamp":"2026-03-06T23:00:00Z"}'
# More endpoint tests
Test-Endpoint "Settings Update" "$baseUrl/api/settings_update" "Post" $settingsHeaders $settingsPayload
Test-Endpoint "User Export" "$baseUrl/api/user_export" "Post" $userExportHeaders $userExportPayload
Test-Endpoint "Incident Archive" "$baseUrl/api/incident_archive" "Post" $incidentArchiveHeaders $incidentArchivePayload
$envHeaders = @{Authorization = "Bearer $jwt"; "X-Env-Mode" = "staging"}
$logArchiveHeaders = @{Authorization = "Bearer $jwt"; "X-Log-Archive" = "true"}
$feedbackExportHeaders = @{Authorization = "Bearer $jwt"; "X-Export-Feedback" = "all"}

$envPayload = '{"env_id":"env-001","mode":"staging","updated_by":"ops_team","timestamp":"2026-03-06T22:00:00Z"}'
$logArchivePayload = '{"archive_id":"log-003","type":"log","files":["log1.txt","log2.txt"],"archived_by":"user333","timestamp":"2026-03-06T22:00:00Z"}'
$feedbackExportPayload = '{"export_id":"exp-001","type":"feedback","count":100,"requested_by":"qa_team","timestamp":"2026-03-06T22:00:00Z"}'
# More endpoint tests
Test-Endpoint "Environment Update" "$baseUrl/api/environment_update" "Post" $envHeaders $envPayload
Test-Endpoint "Log Archive" "$baseUrl/api/log_archive" "Post" $logArchiveHeaders $logArchivePayload
Test-Endpoint "Feedback Export" "$baseUrl/api/feedback_export" "Post" $feedbackExportHeaders $feedbackExportPayload
$serviceHeaders = @{Authorization = "Bearer $jwt"; "X-Service-Name" = "auth"}
$artifactDownloadHeaders = @{Authorization = "Bearer $jwt"; "X-Download-Request" = "true"}
$reportPdfHeaders = @{Authorization = "Bearer $jwt"; "X-Report-Format" = "pdf"}

$servicePayload = '{"service_id":"svc-001","name":"auth","status":"running","checked_by":"ops_team","timestamp":"2026-03-06T21:00:00Z"}'
$artifactDownloadPayload = '{"artifact_id":"art-002","type":"log","download_url":"https://example.com/artifacts/log.txt","requested_by":"user555","timestamp":"2026-03-06T21:00:00Z"}'
$reportPdfPayload = '{"report_id":"pdf-001","type":"build","format":"pdf","generated_by":"qa_team","timestamp":"2026-03-06T21:00:00Z"}'
# More endpoint tests
Test-Endpoint "Service Status" "$baseUrl/api/service_status" "Post" $serviceHeaders $servicePayload
Test-Endpoint "Download Artifact" "$baseUrl/api/download_artifact" "Post" $artifactDownloadHeaders $artifactDownloadPayload
Test-Endpoint "PDF Report" "$baseUrl/api/pdf_report" "Post" $reportPdfHeaders $reportPdfPayload
$integrationHeaders = @{Authorization = "Bearer $jwt"; "X-Integration-Type" = "external"}
$summaryReportHeaders = @{Authorization = "Bearer $jwt"; "X-Report-Type" = "summary"}
$mentionHeaders = @{Authorization = "Bearer $jwt"; "X-Mention-User" = "dev-team"}

$integrationPayload = '{"integration_id":"int-001","service":"datadog","status":"active","triggered_by":"build","timestamp":"2026-03-06T20:00:00Z"}'
$summaryReportPayload = '{"report_id":"sum-002","type":"summary","status":"success","generated_by":"qa_team","timestamp":"2026-03-06T20:00:00Z"}'
$mentionPayload = '{"mention_id":"men-001","user":"dev-team","reason":"build failure","timestamp":"2026-03-06T20:00:00Z"}'
# Additional endpoint tests
Test-Endpoint "External Integration" "$baseUrl/api/external_integration" "Post" $integrationHeaders $integrationPayload
Test-Endpoint "Summary Report" "$baseUrl/api/summary_report" "Post" $summaryReportHeaders $summaryReportPayload
Test-Endpoint "Mention User" "$baseUrl/api/mention_user" "Post" $mentionHeaders $mentionPayload
$qaHeaders = @{Authorization = "Bearer $jwt"; "X-QA-Check" = "true"}
$devHeaders = @{Authorization = "Bearer $jwt"; "X-Dev-Mode" = "enabled"}
$metricsHeaders = @{Authorization = "Bearer $jwt"; "X-Metrics-Request" = "true"}

$qaPayload = '{"qa_id":"qa-001","test_case":"login","result":"passed","checked_by":"qa_team","timestamp":"2026-03-06T19:00:00Z"}'
$devPayload = '{"dev_id":"dev-001","feature":"new_dashboard","status":"deployed","deployed_by":"dev_team","timestamp":"2026-03-06T19:00:00Z"}'
$metricsPayload = '{"metrics_id":"met-001","type":"performance","value":99.5,"collected_by":"monitor_bot","timestamp":"2026-03-06T19:00:00Z"}'
# Even more endpoint tests
Test-Endpoint "QA Check" "$baseUrl/api/qa_check" "Post" $qaHeaders $qaPayload
Test-Endpoint "Dev Deployment" "$baseUrl/api/dev_deployment" "Post" $devHeaders $devPayload
Test-Endpoint "Performance Metrics" "$baseUrl/api/performance_metrics" "Post" $metricsHeaders $metricsPayload
$ticketHeaders = @{Authorization = "Bearer $jwt"; "X-Ticket-Type" = "bug"}
$dashboardHeaders = @{Authorization = "Bearer $jwt"; "X-Dashboard-Access" = "full"}
$attachmentHeaders = @{Authorization = "Bearer $jwt"; "X-Attachment-Type" = "log"}

$ticketPayload = '{"ticket_id":"ticket-001","type":"bug","summary":"Build failure","description":"Build failed due to test errors","reported_by":"user777","timestamp":"2026-03-06T18:00:00Z"}'
$dashboardPayload = '{"dashboard_id":"dash-001","access_level":"full","requested_by":"admin002","timestamp":"2026-03-06T18:00:00Z"}'
$attachmentPayload = '{"attachment_id":"attach-001","type":"log","file_url":"https://example.com/artifacts/build-log.txt","uploaded_by":"user777","timestamp":"2026-03-06T18:00:00Z"}'
# More endpoint tests
Test-Endpoint "Create Ticket" "$baseUrl/api/create_ticket" "Post" $ticketHeaders $ticketPayload
Test-Endpoint "Dashboard Access" "$baseUrl/api/dashboard_access" "Post" $dashboardHeaders $dashboardPayload
Test-Endpoint "Upload Attachment" "$baseUrl/api/upload_attachment" "Post" $attachmentHeaders $attachmentPayload
$notificationHeaders = @{Authorization = "Bearer $jwt"; "X-Notification-Type" = "alert"}
$artifactHeaders = @{Authorization = "Bearer $jwt"; "X-Artifact-Request" = "true"}
$summaryHeaders = @{Authorization = "Bearer $jwt"; "X-Summary-Mode" = "compact"}

$notificationPayload = '{"notification_id":"notif-001","type":"alert","message":"Build failed","severity":"high","timestamp":"2026-03-06T17:00:00Z"}'
$artifactPayload = '{"artifact_id":"art-001","type":"coverage","requested_by":"user888","timestamp":"2026-03-06T17:00:00Z"}'
$summaryPayload = '{"summary_id":"sum-001","type":"build","status":"failed","details":"Build failed due to test errors","timestamp":"2026-03-06T17:00:00Z"}'
# Additional endpoint tests
Test-Endpoint "Send Notification" "$baseUrl/api/send_notification" "Post" $notificationHeaders $notificationPayload
Test-Endpoint "Request Artifact" "$baseUrl/api/request_artifact" "Post" $artifactHeaders $artifactPayload
Test-Endpoint "Build Summary" "$baseUrl/api/build_summary" "Post" $summaryHeaders $summaryPayload
$userHeaders = @{Authorization = "Bearer $jwt"; "X-User-Role" = "standard"}
$adminActionHeaders = @{Authorization = "Bearer $jwt"; "X-Admin-Action" = "true"}
$logHeaders = @{Authorization = "Bearer $jwt"; "X-Log-Request" = "true"}
$reportingHeaders = @{Authorization = "Bearer $jwt"; "X-Reporting-Mode" = "detailed"}

$userPayload = '{"user_id":"user321","action":"update_profile","fields":{"email":"user321@example.com","phone":"+9876543210"},"timestamp":"2026-03-06T16:00:00Z"}'
$adminActionPayload = '{"admin_id":"admin001","action":"reset_password","target_user":"user321","timestamp":"2026-03-06T16:00:00Z"}'
$logPayload = '{"log_id":"log-001","event":"login_attempt","user":"user321","status":"success","timestamp":"2026-03-06T16:00:00Z"}'
$reportingPayload = '{"report_id":"rep-002","type":"detailed","requested_by":"admin001","timestamp":"2026-03-06T16:00:00Z"}'
# Further endpoint tests
Test-Endpoint "User Profile Update" "$baseUrl/api/user_profile" "Post" $userHeaders $userPayload
Test-Endpoint "Admin Action" "$baseUrl/api/admin_action" "Post" $adminActionHeaders $adminActionPayload
Test-Endpoint "Log Event" "$baseUrl/api/log_event" "Post" $logHeaders $logPayload
Test-Endpoint "Detailed Reporting" "$baseUrl/api/detailed_reporting" "Post" $reportingHeaders $reportingPayload
$monitorHeaders = @{Authorization = "Bearer $jwt"; "X-Monitor-Mode" = "active"; "X-Alert-Level" = "high"}
$monitorPayload = '{"monitor_id":"mon-001","service":"api_gateway","status":"active","alert_level":"high","checked_by":"user999","timestamp":"2026-03-06T15:00:00Z"}'
# Highly specific endpoint test
Test-Endpoint "Setup Monitoring" "$baseUrl/api/setup_monitoring" "Post" $monitorHeaders $monitorPayload
$ztHeaders = @{Authorization = "Bearer $jwt"; "X-Zero-Trust" = "enabled"; "X-Env" = "prod"}
$archiveHeaders = @{Authorization = "Bearer $jwt"; "X-Archive-Request" = "true"}
$reportHeaders = @{Authorization = "Bearer $jwt"; "X-Report-Format" = "pdf"}
$sensitiveHeaders = @{Authorization = "Bearer $jwt"; "X-Sensitive-Access" = "true"}

$archivePayload = '{"archive_id":"arch-001","type":"daily","requested_by":"user789","timestamp":"2026-03-06T14:00:00Z"}'
$reportPayload = '{"report_id":"rep-001","type":"summary","format":"pdf","generated_by":"user789","timestamp":"2026-03-06T14:00:00Z"}'
$sensitivePayload = '{"resource_id":"res-002","access_level":"sensitive","requested_by":"user789","reason":"audit","timestamp":"2026-03-06T14:00:00Z"}'
# Granular endpoint tests
Test-Endpoint "Zero Trust Policy" "$baseUrl/api/zero_trust_policy" "Get" $ztHeaders
Test-Endpoint "Archive Request" "$baseUrl/api/archive" "Post" $archiveHeaders $archivePayload
Test-Endpoint "Generate Report" "$baseUrl/api/generate_report" "Post" $reportHeaders $reportPayload
Test-Endpoint "Sensitive Resource Access" "$baseUrl/api/sensitive_access" "Post" $sensitiveHeaders $sensitivePayload
$authHeaders = @{Authorization = "Bearer $jwt"}
$adminHeaders = @{Authorization = "Bearer $jwt"; "X-Admin-Access" = "true"}
$auditHeaders = @{Authorization = "Bearer $jwt"; "X-Audit-Mode" = "enabled"}
$feedbackHeaders = @{Authorization = "Bearer $jwt"; "X-Feedback-Source" = "automation"}
$incidentHeaders = @{Authorization = "Bearer $jwt"; "X-Incident-Reporter" = "user123"}

$customFeedbackPayload = '{"feedback":"Automated feedback for endpoint","user_id":"user456","rating":4,"details":"Endpoint-specific feedback.","tags":["endpoint","test"],"timestamp":"2026-03-06T13:00:00Z"}'
$customIncidentPayload = '{"incident_id":"inc-2026-002","type":"data_leak","severity":"critical","reported_by":"user456","timestamp":"2026-03-06T13:00:00Z","description":"Sensitive data exposure detected."}'
$customAuditPayload = '{"audit_id":"audit-002","action":"access","user":"user456","timestamp":"2026-03-06T13:00:00Z","details":"Accessed admin panel."}'
# Targeted endpoint tests with customizations
Test-Endpoint "Submit Feedback (Custom)" "$baseUrl/api/submit_feedback" "Post" $feedbackHeaders $customFeedbackPayload
Test-Endpoint "Incident (Custom)" "$baseUrl/api/incidents" "Post" $incidentHeaders $customIncidentPayload
Test-Endpoint "Audit Trail (Custom)" "$baseUrl/api/audit_trail" "Post" $auditHeaders $customAuditPayload
Test-Endpoint "Fetch Feedback (Admin)" "$baseUrl/api/fetch_feedback" "Get" $adminHeaders
Test-Endpoint "Insights (Auth)" "$baseUrl/api/insights" "Get" $authHeaders
$customHeaders = @{Authorization = "Bearer $jwt"; "X-Request-ID" = "req-12345"; "X-Custom-Header" = "custom-value"}
$deletePayload = '{"resource_id":"res-001","reason":"Cleanup requested","requested_by":"admin"}'
$putPayload = '{"config_id":"cfg-001","settings":{"max_users":100,"timeout":30},"updated_by":"admin","updated_on":"2026-03-06T12:00:00Z"}'
$patchPayload = '{"patch_id":"patch-002","status":"pending","notes":"Scheduled for tonight"}'
# Test endpoints
...existing code...
# Additional endpoints with custom payloads and varied methods
Test-Endpoint "Delete Resource" "$baseUrl/api/resource" "Delete" $customHeaders $deletePayload
Test-Endpoint "Update Config" "$baseUrl/api/config" "Put" $customHeaders $putPayload
Test-Endpoint "Patch Update" "$baseUrl/api/patch_update" "Patch" $customHeaders $patchPayload
Test-Endpoint "Get Info" "$baseUrl/api/info" "Get" $customHeaders
Test-Endpoint "Head Request" "$baseUrl/api/health" "Head" $customHeaders
$warningsPayload = '{"warning_id":"warn-001","message":"Potential misconfiguration detected","severity":"medium","timestamp":"2026-03-06T12:00:00Z","affected_component":"auth_module"}'
$criticalIssuesPayload = '{"issue_id":"crit-001","title":"Database outage","description":"Main DB unreachable","severity":"critical","reported_on":"2026-03-06T12:00:00Z","status":"open"}'
$contactsPayload = '{"contact_id":"cont-001","name":"Jane Doe","role":"Security Lead","email":"jane.doe@example.com","phone":"+1234567890"}'
$deploymentsPayload = '{"deployment_id":"dep-001","service":"webapp","version":"v2.3","deployed_on":"2026-03-06T12:00:00Z","status":"success"}'
$emailRecipientsPayload = '{"recipient_id":"rec-001","email":"recipient@example.com","type":"notification","subscribed":true}'
# Test endpoints
...existing code...
# Additional endpoints with custom payloads
Test-Endpoint "Warnings" "$baseUrl/api/warnings" "Post" @{Authorization = "Bearer $jwt"} $warningsPayload
Test-Endpoint "Critical Issues" "$baseUrl/api/critical_issues" "Post" @{Authorization = "Bearer $jwt"} $criticalIssuesPayload
Test-Endpoint "Contacts" "$baseUrl/api/contacts" "Post" @{Authorization = "Bearer $jwt"} $contactsPayload
Test-Endpoint "Deployments" "$baseUrl/api/deployments" "Post" @{Authorization = "Bearer $jwt"} $deploymentsPayload
Test-Endpoint "Email Recipients" "$baseUrl/api/email_recipients" "Post" @{Authorization = "Bearer $jwt"} $emailRecipientsPayload

# Enhanced FastAPI endpoint test script
$jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIn0.odcuX-3XYfCfAJ3nks4b8kWfmFQJaZMEDcewwSM69R4"
$baseUrl = "https://powerful-crag-32515-746bfe377fb4.herokuapp.com"
$logFile = "fastapi_test_results.log"

function Test-Endpoint {
	param(
		[string]$Name,
		[string]$Uri,
		[string]$Method = "Get",
		[hashtable]$Headers = @{},
		[string]$Body = $null
	)
	Write-Host "Testing $Name..."
	$result = $null
	try {
		if ($Body) {
			$result = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -ContentType "application/json" -Body $Body
		} else {
			$result = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers
		}
		$pretty = $result | ConvertTo-Json -Depth 10
		$output = "[$Name] Success:`n$pretty"
	} catch {
		$output = "[$Name] Error:`n$($_.Exception.Message)"
	}
	Write-Host $output
	Add-Content -Path $logFile -Value $output
}

# Clear log file
if (Test-Path $logFile) { Remove-Item $logFile }


# Custom payloads
$feedbackPayload = '{"feedback":"Automated feedback","user_id":"user123","rating":5,"details":"This is a test feedback with extra fields."}'
$retrainPayload = '[{"feedback":"Automated feedback","user_id":"user123","timestamp":"2026-03-06T12:00:00Z"}]'
$blockDomainPayload = '{"domain":"example.com","reason":"Suspicious activity detected","blocked_by":"admin"}'
$userActivityPayload = '{"user_id":"user123","action":"login","timestamp":"2026-03-06T12:00:00Z"}'
$patchStatusPayload = '{"patch_id":"patch-001","status":"applied","applied_by":"admin","applied_on":"2026-03-06T12:00:00Z"}'
$vulnScanPayload = '{"scan_id":"scan-001","result":"clean","scanned_by":"security_bot","scanned_on":"2026-03-06T12:00:00Z"}'
$feedbackPayload = '{"feedback":"Automated feedback","user_id":"user123","rating":5,"details":"This is a test feedback with extra fields.","tags":["security","usability"],"timestamp":"2026-03-06T12:00:00Z"}'
$retrainPayload = '[{"feedback":"Automated feedback","user_id":"user123","timestamp":"2026-03-06T12:00:00Z","model_version":"v2.1","retrain_reason":"periodic"}]'
$blockDomainPayload = '{"domain":"example.com","reason":"Suspicious activity detected","blocked_by":"admin","block_duration":"24h"}'
$userActivityPayload = '{"user_id":"user123","action":"login","timestamp":"2026-03-06T12:00:00Z","ip_address":"192.168.1.100","device":"Windows-PC"}'
$patchStatusPayload = '{"patch_id":"patch-001","status":"applied","applied_by":"admin","applied_on":"2026-03-06T12:00:00Z","patch_type":"security","notes":"Critical vulnerability patched."}'
$vulnScanPayload = '{"scan_id":"scan-001","result":"clean","scanned_by":"security_bot","scanned_on":"2026-03-06T12:00:00Z","scan_type":"full","vulnerabilities":[]}'
$incidentPayload = '{"incident_id":"inc-2026-001","type":"unauthorized_access","severity":"high","reported_by":"user123","timestamp":"2026-03-06T12:00:00Z","description":"Unauthorized access detected on admin panel."}'
$assetInventoryPayload = '{"asset_id":"asset-001","name":"Server01","type":"VM","location":"DataCenter1","status":"active","owner":"ITDept"}'
$compliancePayload = '{"compliance_id":"comp-001","standard":"ISO27001","status":"passed","checked_on":"2026-03-06T12:00:00Z","checked_by":"auditor"}'

# Test endpoints
Test-Endpoint "Root" "$baseUrl/"
Test-Endpoint "Submit Feedback" "$baseUrl/api/submit_feedback" "Post" @{Authorization = "Bearer $jwt"} $feedbackPayload
Test-Endpoint "Fetch Feedback" "$baseUrl/api/fetch_feedback" "Get" @{Authorization = "Bearer $jwt"}
Test-Endpoint "Retrain Model" "$baseUrl/api/retrain_model" "Post" @{Authorization = "Bearer $jwt"} $retrainPayload
Test-Endpoint "Insights" "$baseUrl/api/insights" "Get" @{Authorization = "Bearer $jwt"}
Test-Endpoint "Live Accuracy" "$baseUrl/api/live_accuracy" "Get" @{Authorization = "Bearer $jwt"}
Test-Endpoint "Audit Trail" "$baseUrl/api/audit_trail" "Get" @{Authorization = "Bearer $jwt"}
Test-Endpoint "Block Domain" "$baseUrl/block-domain" "Post" @{} $blockDomainPayload

# Additional endpoints with custom payloads
Test-Endpoint "User Activity" "$baseUrl/api/user_activity" "Post" @{Authorization = "Bearer $jwt"} $userActivityPayload
Test-Endpoint "Patch Status" "$baseUrl/api/patch_status" "Post" @{Authorization = "Bearer $jwt"} $patchStatusPayload
Test-Endpoint "Vuln Scan" "$baseUrl/api/vuln_scan" "Post" @{Authorization = "Bearer $jwt"} $vulnScanPayload
Test-Endpoint "Incident" "$baseUrl/api/incidents" "Post" @{Authorization = "Bearer $jwt"} $incidentPayload
Test-Endpoint "Asset Inventory" "$baseUrl/api/asset_inventory" "Post" @{Authorization = "Bearer $jwt"} $assetInventoryPayload
Test-Endpoint "Compliance" "$baseUrl/api/compliance" "Post" @{Authorization = "Bearer $jwt"} $compliancePayload

# Example: Add custom endpoint
# Advanced policy simulation endpoints
# Enterprise compliance and SIEM/ITSM integration endpoints
# Advanced audit, risk assessment, and external reporting integrations
# Advanced threat intelligence, remediation, and compliance export endpoints
# Advanced analytics, anomaly detection, and user access review endpoints
# Advanced logging, audit export, and compliance verification endpoints
# Advanced notification, escalation, and incident response endpoints
# Advanced backup, restore, and system health check endpoints
# Advanced export, import, and configuration update endpoints
# Advanced scheduling, task automation, and permission update endpoints
# Advanced user management, group assignment, and role update endpoints
$userMgmtHeaders = @{Authorization = "Bearer $jwt"; "X-User-Management" = "enabled"}
$groupAssignHeaders = @{Authorization = "Bearer $jwt"; "X-Group-Assignment" = "true"}
$roleUpdateHeaders = @{Authorization = "Bearer $jwt"; "X-Role-Update" = "true"}
$userMgmtPayload = '{"user_id": "user789", "action": "create", "created_by": "admin", "timestamp": "2026-03-07T00:30:00Z"}'
$groupAssignPayload = '{"group_id": "grp-001", "user": "user789", "assigned_by": "admin", "timestamp": "2026-03-07T00:31:00Z"}'
$roleUpdatePayload = '{"role_id": "role-002", "user": "user789", "role": "editor", "updated_by": "admin", "timestamp": "2026-03-07T00:32:00Z"}'

Test-Endpoint "User Management" "$baseUrl/api/user_management" "Post" $userMgmtHeaders $userMgmtPayload
Test-Endpoint "Group Assignment" "$baseUrl/api/group_assignment" "Post" $groupAssignHeaders $groupAssignPayload
Test-Endpoint "Role Update" "$baseUrl/api/role_update" "Post" $roleUpdateHeaders $roleUpdatePayload
$schedulingHeaders = @{Authorization = "Bearer $jwt"; "X-Scheduling-Mode" = "auto"}
$automationHeaders = @{Authorization = "Bearer $jwt"; "X-Automation-Task" = "enabled"}
$permissionUpdateHeaders = @{Authorization = "Bearer $jwt"; "X-Permission-Update" = "true"}
$schedulingPayload = '{"schedule_id": "sch-001", "task": "backup", "interval": "daily", "scheduled_by": "admin", "timestamp": "2026-03-07T00:25:00Z"}'
$automationPayload = '{"automation_id": "auto-001", "task": "report_generation", "status": "completed", "executed_by": "automation_bot", "timestamp": "2026-03-07T00:26:00Z"}'
$permissionUpdatePayload = '{"permission_id": "perm-001", "user": "user123", "role": "admin", "updated_by": "admin", "timestamp": "2026-03-07T00:27:00Z"}'

Test-Endpoint "Advanced Scheduling" "$baseUrl/api/advanced_scheduling" "Post" $schedulingHeaders $schedulingPayload
Test-Endpoint "Task Automation" "$baseUrl/api/task_automation" "Post" $automationHeaders $automationPayload
Test-Endpoint "Permission Update" "$baseUrl/api/permission_update" "Post" $permissionUpdateHeaders $permissionUpdatePayload
$exportHeaders2 = @{Authorization = "Bearer $jwt"; "X-Export-Mode" = "bulk"}
$importHeaders2 = @{Authorization = "Bearer $jwt"; "X-Import-Mode" = "bulk"}
$configUpdateHeaders = @{Authorization = "Bearer $jwt"; "X-Config-Update" = "true"}
$exportPayload2 = '{"export_id": "exp-003", "type": "bulk", "exported_by": "admin", "timestamp": "2026-03-07T00:20:00Z"}'
$importPayload2 = '{"import_id": "imp-003", "type": "bulk", "imported_by": "admin", "timestamp": "2026-03-07T00:21:00Z"}'
$configUpdatePayload = '{"config_id": "cfg-002", "changes": {"timeout": 60, "max_users": 200}, "updated_by": "admin", "timestamp": "2026-03-07T00:22:00Z"}'

Test-Endpoint "Advanced Export" "$baseUrl/api/advanced_export" "Post" $exportHeaders2 $exportPayload2
Test-Endpoint "Advanced Import" "$baseUrl/api/advanced_import" "Post" $importHeaders2 $importPayload2
Test-Endpoint "Configuration Update" "$baseUrl/api/configuration_update" "Post" $configUpdateHeaders $configUpdatePayload
$backupHeaders2 = @{Authorization = "Bearer $jwt"; "X-Backup-Mode" = "scheduled"}
$restoreHeaders2 = @{Authorization = "Bearer $jwt"; "X-Restore-Mode" = "full"}
$healthCheckHeaders = @{Authorization = "Bearer $jwt"; "X-Health-Check" = "enabled"}
$backupPayload2 = '{"backup_id": "bkp-002", "type": "scheduled", "scheduled_by": "admin", "timestamp": "2026-03-07T00:15:00Z"}'
$restorePayload2 = '{"restore_id": "rst-002", "type": "full", "restored_by": "ops_team", "timestamp": "2026-03-07T00:16:00Z"}'
$healthCheckPayload = '{"health_id": "hlth-001", "status": "healthy", "checked_by": "monitor_bot", "timestamp": "2026-03-07T00:17:00Z"}'

Test-Endpoint "Advanced Backup" "$baseUrl/api/advanced_backup" "Post" $backupHeaders2 $backupPayload2
Test-Endpoint "Advanced Restore" "$baseUrl/api/advanced_restore" "Post" $restoreHeaders2 $restorePayload2
Test-Endpoint "System Health Check" "$baseUrl/api/system_health_check" "Post" $healthCheckHeaders $healthCheckPayload
$notificationHeaders2 = @{Authorization = "Bearer $jwt"; "X-Notification-Mode" = "urgent"}
$escalationHeaders2 = @{Authorization = "Bearer $jwt"; "X-Escalation-Level" = "critical"}
$incidentResponseHeaders = @{Authorization = "Bearer $jwt"; "X-Incident-Response" = "active"}
$notificationPayload2 = '{"notification_id": "notif-002", "type": "urgent", "message": "Critical system failure", "sent_by": "alert_bot", "timestamp": "2026-03-07T00:10:00Z"}'
$escalationPayload2 = '{"escalation_id": "esc-002", "level": "critical", "triggered_by": "monitor_bot", "timestamp": "2026-03-07T00:11:00Z"}'
$incidentResponsePayload = '{"incident_id": "inc-003", "type": "system_failure", "status": "resolved", "responded_by": "incident_team", "timestamp": "2026-03-07T00:12:00Z"}'

Test-Endpoint "Advanced Notification" "$baseUrl/api/advanced_notification" "Post" $notificationHeaders2 $notificationPayload2
Test-Endpoint "Escalation" "$baseUrl/api/escalation" "Post" $escalationHeaders2 $escalationPayload2
Test-Endpoint "Incident Response" "$baseUrl/api/incident_response" "Post" $incidentResponseHeaders $incidentResponsePayload
$loggingHeaders = @{Authorization = "Bearer $jwt"; "X-Logging-Mode" = "verbose"}
$auditExportHeaders = @{Authorization = "Bearer $jwt"; "X-Audit-Export" = "true"}
$complianceVerifyHeaders = @{Authorization = "Bearer $jwt"; "X-Compliance-Verify" = "enabled"}
$loggingPayload = '{"log_id": "log-002", "level": "verbose", "events": ["login", "logout"], "logged_by": "log_team", "timestamp": "2026-03-07T00:05:00Z"}'
$auditExportPayload = '{"export_id": "audit-exp-001", "scope": "full", "status": "exported", "exported_by": "audit_team", "timestamp": "2026-03-07T00:06:00Z"}'
$complianceVerifyPayload = '{"verify_id": "comp-ver-001", "framework": "HIPAA", "status": "verified", "verified_by": "compliance_team", "timestamp": "2026-03-07T00:07:00Z"}'

Test-Endpoint "Advanced Logging" "$baseUrl/api/advanced_logging" "Post" $loggingHeaders $loggingPayload
Test-Endpoint "Audit Export" "$baseUrl/api/audit_export" "Post" $auditExportHeaders $auditExportPayload
Test-Endpoint "Compliance Verification" "$baseUrl/api/compliance_verification" "Post" $complianceVerifyHeaders $complianceVerifyPayload
$analyticsHeaders = @{Authorization = "Bearer $jwt"; "X-Analytics-Mode" = "deep"}
$anomalyHeaders = @{Authorization = "Bearer $jwt"; "X-Anomaly-Detection" = "enabled"}
$accessReviewHeaders = @{Authorization = "Bearer $jwt"; "X-Access-Review" = "true"}
$analyticsPayload = '{"analytics_id": "anl-001", "scope": "deep", "metrics": ["usage", "performance"], "generated_by": "analytics_team", "timestamp": "2026-03-06T23:59:00Z"}'
$anomalyPayload = '{"anomaly_id": "anm-001", "type": "access", "detected_by": "monitor_bot", "timestamp": "2026-03-07T00:00:00Z"}'
$accessReviewPayload = '{"review_id": "rev-001", "users": ["user123", "user456"], "status": "completed", "reviewed_by": "admin", "timestamp": "2026-03-07T00:01:00Z"}'

Test-Endpoint "Advanced Analytics" "$baseUrl/api/advanced_analytics" "Post" $analyticsHeaders $analyticsPayload
Test-Endpoint "Anomaly Detection" "$baseUrl/api/anomaly_detection" "Post" $anomalyHeaders $anomalyPayload
Test-Endpoint "User Access Review" "$baseUrl/api/user_access_review" "Post" $accessReviewHeaders $accessReviewPayload
$threatIntelHeaders = @{Authorization = "Bearer $jwt"; "X-Threat-Intel" = "enabled"}
$remediationHeaders = @{Authorization = "Bearer $jwt"; "X-Remediation" = "auto"}
$complianceExportHeaders = @{Authorization = "Bearer $jwt"; "X-Compliance-Export" = "true"}
$threatIntelPayload = '{"intel_id": "ti-001", "source": "external_feed", "threats": ["malware", "phishing"], "collected_by": "threat_team", "timestamp": "2026-03-06T23:55:00Z"}'
$remediationPayload = '{"remediation_id": "rem-001", "action": "quarantine", "target": "server01", "status": "completed", "performed_by": "sec_team", "timestamp": "2026-03-06T23:56:00Z"}'
$complianceExportPayload = '{"export_id": "comp-exp-001", "framework": "GDPR", "status": "exported", "exported_by": "compliance_team", "timestamp": "2026-03-06T23:57:00Z"}'

Test-Endpoint "Threat Intelligence" "$baseUrl/api/threat_intelligence" "Post" $threatIntelHeaders $threatIntelPayload
Test-Endpoint "Automated Remediation" "$baseUrl/api/automated_remediation" "Post" $remediationHeaders $remediationPayload
Test-Endpoint "Compliance Export" "$baseUrl/api/compliance_export" "Post" $complianceExportHeaders $complianceExportPayload
$auditRiskHeaders = @{Authorization = "Bearer $jwt"; "X-Audit-Risk" = "deep"}
$externalReportHeaders = @{Authorization = "Bearer $jwt"; "X-External-Report" = "enabled"}
$riskAssessmentHeaders = @{Authorization = "Bearer $jwt"; "X-Risk-Assessment" = "active"}
$externalExportHeaders = @{Authorization = "Bearer $jwt"; "X-External-Export" = "true"}

$auditRiskPayload = '{"audit_id": "risk-001", "scope": "deep", "risks": ["access_control", "data_leak"], "assessed_by": "risk_team", "timestamp": "2026-03-06T23:50:00Z"}'
$externalReportPayload = '{"report_id": "ext-001", "type": "incident", "status": "submitted", "submitted_to": "external_authority", "timestamp": "2026-03-06T23:51:00Z"}'
$riskAssessmentPayload = '{"assessment_id": "ra-001", "areas": ["network", "application"], "status": "completed", "assessed_by": "security_team", "timestamp": "2026-03-06T23:52:00Z"}'
$externalExportPayload = '{"export_id": "exp-001", "format": "csv", "destination": "external_storage", "requested_by": "admin", "timestamp": "2026-03-06T23:53:00Z"}'

Test-Endpoint "Audit Risk Assessment" "$baseUrl/api/audit_risk_assessment" "Post" $auditRiskHeaders $auditRiskPayload
Test-Endpoint "External Report Submission" "$baseUrl/api/external_report_submission" "Post" $externalReportHeaders $externalReportPayload
Test-Endpoint "Risk Assessment" "$baseUrl/api/risk_assessment" "Post" $riskAssessmentHeaders $riskAssessmentPayload
Test-Endpoint "External Export" "$baseUrl/api/external_export" "Post" $externalExportHeaders $externalExportPayload
$enterpriseComplianceHeaders = @{Authorization = "Bearer $jwt"; "X-Compliance-Mode" = "enterprise"}
$siemHeaders = @{Authorization = "Bearer $jwt"; "X-SIEM-Integration" = "enabled"}
$itsmHeaders = @{Authorization = "Bearer $jwt"; "X-ITSM-Integration" = "active"}
$governanceHeaders = @{Authorization = "Bearer $jwt"; "X-Governance-Check" = "true"}

$enterpriseCompliancePayload = '{"compliance_id": "ent-001", "framework": "NIST", "status": "approved", "audited_by": "external_auditor", "timestamp": "2026-03-06T23:40:00Z"}'
$siemPayload = '{"integration_id": "siem-001", "platform": "Splunk", "status": "connected", "events": ["login", "alert"], "timestamp": "2026-03-06T23:41:00Z"}'
$itsmPayload = '{"integration_id": "itsm-001", "platform": "ServiceNow", "status": "active", "incidents": ["INC123", "INC124"], "timestamp": "2026-03-06T23:42:00Z"}'
$governancePayload = '{"governance_id": "gov-001", "policy": "access_control", "status": "enforced", "checked_by": "compliance_team", "timestamp": "2026-03-06T23:43:00Z"}'

Test-Endpoint "Enterprise Compliance" "$baseUrl/api/enterprise_compliance" "Post" $enterpriseComplianceHeaders $enterpriseCompliancePayload
Test-Endpoint "SIEM Integration" "$baseUrl/api/siem_integration" "Post" $siemHeaders $siemPayload
Test-Endpoint "ITSM Integration" "$baseUrl/api/itsm_integration" "Post" $itsmHeaders $itsmPayload
Test-Endpoint "Governance Check" "$baseUrl/api/governance_check" "Post" $governanceHeaders $governancePayload
$policySimHeaders = @{Authorization = "Bearer $jwt"; "X-Policy-Sim" = "true"}
$escalationHeaders = @{Authorization = "Bearer $jwt"; "X-Escalation-Test" = "enabled"}
$batchSimHeaders = @{Authorization = "Bearer $jwt"; "X-Batch-Sim" = "multi"}
$scheduledTestHeaders = @{Authorization = "Bearer $jwt"; "X-Scheduled-Test" = "active"}

$policySimPayload = '{"level": "high", "policies": ["policyA", "policyB"], "api_url": "https://example.com/api/policy_sim", "token": "$jwt", "timestamp": "2026-03-06T23:30:00Z"}'
$escalationPayload = '{"tampering_level": "critical", "policies": ["policyA", "policyB"], "api_url": "https://example.com/api/escalation", "token": "$jwt", "timestamp": "2026-03-06T23:31:00Z"}'
$batchSimPayload = '{"levels": ["low", "medium", "high"], "policies": ["policyA", "policyB"], "api_url": "https://example.com/api/batch_sim", "token": "$jwt", "timestamp": "2026-03-06T23:32:00Z"}'
$scheduledTestPayload = '{"policies": ["policyA", "policyB"], "api_url": "https://example.com/api/scheduled_test", "token": "$jwt", "interval_minutes": 30, "timestamp": "2026-03-06T23:33:00Z"}'

Test-Endpoint "Policy Simulation" "$baseUrl/api/policy_simulation" "Post" $policySimHeaders $policySimPayload
Test-Endpoint "Escalation Policy Test" "$baseUrl/api/escalation_policy_test" "Post" $escalationHeaders $escalationPayload
Test-Endpoint "Batch Policy Simulation" "$baseUrl/api/batch_policy_simulation" "Post" $batchSimHeaders $batchSimPayload
Test-Endpoint "Scheduled Policy Test" "$baseUrl/api/scheduled_policy_test" "Post" $scheduledTestHeaders $scheduledTestPayload
# Test-Endpoint "Custom Endpoint" "$baseUrl/api/custom" "Get" @{Authorization = "Bearer $jwt"}
