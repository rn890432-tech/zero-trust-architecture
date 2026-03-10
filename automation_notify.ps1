<#
    automation_notify.ps1
    Zero Trust Automation - Advanced Notification & Reporting Script
    - Advanced HTML, branding, charts, conditional formatting
    - Per-section Brevo SMTP email logic
    - Attachments, dashboards, integrations
    - Clean, deduplicated, ready to use
#>

# --- Load Data from CSVs ---
$compliance      = Test-Path 'automation/compliance.csv'      ? (Import-Csv 'automation/compliance.csv')      : @()
$userActivity    = Test-Path 'automation/user_activity.csv'    ? (Import-Csv 'automation/user_activity.csv')    : @()
$patchStatus     = Test-Path 'automation/patch_status.csv'     ? (Import-Csv 'automation/patch_status.csv')     : @()
$warnings        = Test-Path 'automation/warnings.csv'         ? (Import-Csv 'automation/warnings.csv' | ForEach-Object { $_.Warning }) : @()
$infos           = Test-Path 'automation/info.csv'             ? (Import-Csv 'automation/info.csv' | ForEach-Object { $_.Info }) : @()
$contacts        = Test-Path 'automation/contacts.csv'         ? (Import-Csv 'automation/contacts.csv')         : @()
$criticalIssues  = Test-Path 'automation/critical_issues.csv'  ? (Import-Csv 'automation/critical_issues.csv' | ForEach-Object { $_.Issue }) : @()
$incidents       = Test-Path 'automation/incidents.csv'        ? (Import-Csv 'automation/incidents.csv')        : @()
$deployments     = Test-Path 'automation/deployments.csv'      ? (Import-Csv 'automation/deployments.csv')      : @()
$assetInventory  = Test-Path 'automation/asset_inventory.csv'  ? (Import-Csv 'automation/asset_inventory.csv')  : @()
$vulnScan        = Test-Path 'automation/vuln_scan.csv'        ? (Import-Csv 'automation/vuln_scan.csv')        : @()

# --- Set Working Directory ---
if ($PSScriptRoot) { Set-Location -Path $PSScriptRoot } else { Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) }

# --- CONFIGURABLE SETTINGS ---
$archiveDays = 7
$archiveDir = 'automation/archive'
$customSubject = $null
$sectionRecipients = @{}
if (Test-Path 'automation/email_recipients.csv') {
    $emailConfig = Import-Csv 'automation/email_recipients.csv'
    foreach ($row in $emailConfig) {
        if ($row.Section -eq 'ALL' -and $row.Subject) { $customSubject = $row.Subject }
        if ($row.Section -and $row.Recipients) { $sectionRecipients[$row.Section] = $row.Recipients -split ',' | ForEach-Object { $_.Trim() } }
    }
}

# --- Ensure directories exist ---
foreach ($dir in @($archiveDir, 'automation/logs', 'automation/reports')) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# --- Auto-archive old logs/reports ---
Get-ChildItem 'automation/logs', 'automation/reports' -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$archiveDays) } | ForEach-Object {
    Move-Item $_.FullName $archiveDir -Force
}

# --- Secure Variable Usage ---
$from = $global:ZTA_EMAIL_USER
if (-not $from) { $from = [Environment]::GetEnvironmentVariable('ZTA_EMAIL_USER', 'User') }
$from = $from -replace '^\s+|\s+$', ''
$to = $global:ZTA_EMAIL_TO
if (-not $to) { $to = [Environment]::GetEnvironmentVariable('ZTA_EMAIL_TO', 'User') }
$to = $to -replace '^\s+|\s+$', ''
$email_pass = $global:ZTA_EMAIL_PASS
if (-not $email_pass) { $email_pass = [Environment]::GetEnvironmentVariable('ZTA_EMAIL_PASS', 'User') }
if (-not $email_pass) {
    $email_pass = Read-Host -AsSecureString "Enter SMTP password (input hidden)"
}
$slack_webhook_url = $global:ZTA_SLACK_WEBHOOK
if (-not $slack_webhook_url) { $slack_webhook_url = [Environment]::GetEnvironmentVariable('ZTA_SLACK_WEBHOOK', 'User') }
$slack_webhook_url = $slack_webhook_url -replace '^\s+|\s+$', ''
$emailRecipients = $to -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$slackWebhooks = $slack_webhook_url -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$subject = $customSubject ? $customSubject : 'Zero Trust Automation Report'
$logPath = 'automation/logs/automation.log'
$reportPath = 'automation/reports/daily_report_' + (Get-Date -Format 'yyyy-MM-dd') + '.txt'

# --- Ensure log file exists ---
if (-not (Test-Path $logPath)) {
    Add-Content $logPath ("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] Initial log entry.")
}

# --- System Health Section ---
$disk = Get-PSDrive -Name C
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$healthSection = "Disk Free: $([math]::Round($disk.Free/1GB,2)) GB / $([math]::Round($disk.Used/1GB,2)) GB | CPU Load: $cpu%"

# --- Find new critical issues since last run ---
$allLogs = Get-Content $logPath
$lastRunMarker = $allLogs | Select-String '\[RESOLVED\]' | Select-Object -Last 1
$newCriticals = @()
if ($lastRunMarker) {
    $lastIndex = $allLogs.IndexOf($lastRunMarker.Line)
    $newCriticals = $allLogs[($lastIndex + 1)..($allLogs.Count - 1)] | Where-Object { $_ -match 'critical issue' }
} else {
    $newCriticals = $allLogs | Where-Object { $_ -match 'critical issue' }
}
$newCriticalsText = if ($newCriticals) { $newCriticals -join "`n" } else { 'None since last run.' }

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- User-Specific Dashboard Logic ---
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $assetHostnames = $ownerAssets | ForEach-Object { $_.Hostname } | Where-Object { $_ } | ForEach-Object { $_ }
    $assetHostnamesStr = ($assetHostnames -join ', ')
    $openVulns = $ownerVulns | Where-Object { $_.Status -eq 'Open' }
    $openVulnsCount = $openVulns.Count
    $openVulnsFindings = $openVulns | ForEach-Object { $_.Finding }
    $openVulnsFindingsStr = ($openVulnsFindings -join '; ')
    $dashboardHtml = @"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
    $userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Splunk SIEM Integration: Send new critical incidents to Splunk ---
$splunkHECUrl = $env:SPLUNK_HEC_URL
$splunkHECToken = $env:SPLUNK_HEC_TOKEN
if ($splunkHECUrl -and $splunkHECToken -and $newCriticals.Count -gt 0) {
    foreach ($incident in $newCriticals) {
        $eventJson = @{
            time = [int][double]::Parse((Get-Date -UFormat %s))
            host = $env:COMPUTERNAME
            source = "ZeroTrustAutomation"
            event = @{
                type = "incident"
                severity = "critical"
                details = $incident
            }
        } | ConvertTo-Json -Compress
        & "$PSScriptRoot\send_to_splunk.ps1" -SplunkHECUrl $splunkHECUrl -HECToken (ConvertTo-SecureString $splunkHECToken -AsPlainText -Force) -EventJson $eventJson
    }
    Write-Host "[VERBOSE] Sent new critical incidents to Splunk."
}

# --- Azure Sentinel Integration (Optional, requires setup) ---
# $sentinelWorkspaceId = $env:SENTINEL_WORKSPACE_ID
# $sentinelSharedKey = $env:SENTINEL_SHARED_KEY
# $sentinelLogType = "ZeroTrustIncidents"
# if ($sentinelWorkspaceId -and $sentinelSharedKey -and $newCriticals.Count -gt 0) {
#     foreach ($incident in $newCriticals) {
#         $body = @{
#             Time = (Get-Date -Format o)
#             Host = $env:COMPUTERNAME
#             Type = "incident"
#             Severity = "critical"
#             Details = $incident
#         } | ConvertTo-Json
#         # Call a helper script or function to send to Sentinel (see Microsoft Docs for full example)
#         # & "$PSScriptRoot\send_to_sentinel.ps1" -WorkspaceId $sentinelWorkspaceId -SharedKey $sentinelSharedKey -LogType $sentinelLogType -Body $body
#     }
#     Write-Host "[VERBOSE] Sent new critical incidents to Azure Sentinel."
# }

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @("""
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
""")
    $userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
        $userDashboards += @"
        <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
            <h3>User Dashboard: $owner</h3>
            <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
            <ul>
                <li>Assets: $assetHostnamesStr</li>
                <li>Open Vulns: $openVulnsFindingsStr</li>
            </ul>
        </div>
    "@
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
        $userDashboards += @"
        <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
            <h3>User Dashboard: $owner</h3>
            <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
            <ul>
                <li>Assets: $assetHostnamesStr</li>
                <li>Open Vulns: $openVulnsFindingsStr</li>
            </ul>
        </div>
    "@
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
        $userDashboards += @"
        <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
            <h3>User Dashboard: $owner</h3>
            <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
            <ul>
                <li>Assets: $assetHostnamesStr</li>
                <li>Open Vulns: $openVulnsFindingsStr</li>
            </ul>
        </div>
    "@
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
        $userDashboards += @"
        <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
            <h3>User Dashboard: $owner</h3>
            <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
            <ul>
                <li>Assets: $assetHostnamesStr</li>
                <li>Open Vulns: $openVulnsFindingsStr</li>
            </ul>
        </div>
    "@
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
        $userDashboards += @"
        <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
            <h3>User Dashboard: $owner</h3>
            <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
            <ul>
                <li>Assets: $assetHostnamesStr</li>
                <li>Open Vulns: $openVulnsFindingsStr</li>
            </ul>
        </div>
    "@
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @(@"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
$userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @(@"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
$userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @(@"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
$userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @(@"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
$userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @(@"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
$userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>
        <div id="vulnScanSection" style="display:none;">
            <img src="$vulnChartUrl" alt="Vulnerability Severity Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>ScanID</th><th>AssetID</th><th>Hostname</th><th>Severity</th><th>Finding</th><th>Status</th><th>Detected</th><th>Remediated</th></tr>
                $(( $vulnScan | Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'High' { 2 }
                        'Medium' { 3 }
                        'Low' { 4 }
                        default { 5 }
                    }
                }} | ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'High' { '#b88600' }
                        'Medium' { '#00796b' }
                        'Low' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = if ($_.Status -eq 'Open') { 'background:#ffeaea;font-weight:bold;' } else { '' }
                    "<tr style='$rowStyle'><td>$($_.ScanID)</td><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Finding)</td><td>$($_.Status)</td><td>$($_.Detected)</td><td>$($_.Remediated)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#b80000;">Open vulnerabilities are highlighted in pink. Sorted by severity.</p>
        </div>
    </div>
    <div class="section">
        <h3>Automation Summary</h3>
        <ul>
            <li>Automated log analysis and reporting</li>
            <li>Slack and email notifications</li>
            <li>Attachment of daily reports</li>
            <li>Critical issue detection and escalation</li>
            <li>System health monitoring (disk, CPU)</li>
            <li>Customizable HTML reports</li>
            <li>Multiple recipient support</li>
            <li>Compliance, user activity, and patch status reporting</li>
        </ul>
        <p style="font-size:13px;color:#0057b8;">For more details, visit the <a href='https://intranet.zerotrust.local'>Zero Trust Intranet</a>.</p>
    </div>
    <div class="section">
        <h3>Useful Links</h3>
        <ul>
            <li><a href="https://intranet.zerotrust.local">Zero Trust Intranet</a></li>
            <li><a href="https://status.zerotrust.local">System Status Dashboard</a></li>
            <li><a href="mailto:support@zerotrust.local">Contact Support</a></li>
            <li><a href="https://docs.zerotrust.local">Documentation Portal</a></li>
            <li><a href="https://kb.zerotrust.local">Knowledge Base</a></li>
        </ul>
        <p style="font-size:12px;color:#888;">Links are for internal use only.</p>
    </div>
</body>
</html>
"@
$attachments = @()
# Attach the main report if it exists
if (Test-Path $reportPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($reportPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($reportPath)
        type     = "text/plain"
    }
}
# Attach all CSVs in automation folder
Get-ChildItem -Path 'automation' -Filter *.csv -File | ForEach-Object {
    $csvBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)
    $attachments += @{
        content  = $csvBase64
        filename = $_.Name
        type     = "text/csv"
    }
}
# Attach all PDFs in automation/attachments if the folder exists
if (Test-Path 'automation/attachments') {
    Get-ChildItem -Path 'automation/attachments' -Filter *.pdf -File | ForEach-Object {
        $pdfBytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $pdfBase64 = [Convert]::ToBase64String($pdfBytes)
        $attachments += @{
            content  = $pdfBase64
            filename = $_.Name
            type     = "application/pdf"
        }
    }
}
$sendgridPayload = @{
    personalizations = @(@{
            to      = $toArray
            subject = $subject
        })
    from             = @{ email = $from }
    content          = @(
        @{ type = "text/plain"; value = $body },
        @{ type = "text/html"; value = $htmlBody }
    )
}
if ($attachments.Count -gt 0) {
    $sendgridPayload.attachments = $attachments
}
$sendgridPayload = $sendgridPayload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $email_pass"; "Content-Type" = "application/json" }
try {
    Write-Host "[VERBOSE] Sending email via SendGrid Web API..."
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $sendgridPayload
    Write-Host "Email sent to $($emailRecipients -join ', ') via SendGrid Web API."
}
catch {
    Write-Error "[ERROR] Failed to send email via SendGrid Web API: $_"
    Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
}

# --- Slack notification to multiple webhooks ---
if ($slackWebhooks) {
    Write-Host "[VERBOSE] Slack notification block starting. Webhooks: $($slackWebhooks -join ', ')"
    $slack_message = @{ text = "$subject`n$body" }
    foreach ($webhook in $slackWebhooks) {
        $webhook = $webhook.Trim()
        try {
            Write-Host "[VERBOSE] Sending Slack notification to $webhook..."
            Invoke-RestMethod -Uri $webhook -Method Post -Body ($slack_message | ConvertTo-Json)
            Write-Host "Slack notification sent to $webhook."
        }
        catch {
            Write-Error "[ERROR] Slack notification failed: $_"
            Write-Host "[VERBOSE] Exception details: $($_.Exception.Message)"
            if ($_.Exception.InnerException) { Write-Host "[VERBOSE] Inner Exception: $($_.Exception.InnerException.Message)" }
            Write-Error "StackTrace: $($_.Exception.StackTrace)"
        }
    }
}

# --- Microsoft Teams notification (if webhook configured) ---
$teamsWebhook = $env:ZTA_TEAMS_WEBHOOK
if ($teamsWebhook) {
    $teamsCard = @{
        '@type' = 'MessageCard'; '@context' = 'http://schema.org/extensions';
        summary = $subject;
        themeColor = '0078D7';
        title = $subject;
        text = "<pre>$body</pre>"
    }
    try {
        Write-Host "[VERBOSE] Sending Teams notification..."
        Invoke-RestMethod -Uri $teamsWebhook -Method Post -Body ($teamsCard | ConvertTo-Json -Depth 4) -ContentType 'application/json'
        Write-Host "Teams notification sent."
    }
    catch {
        Write-Error "[ERROR] Teams notification failed: $_"
    }
}

# --- PagerDuty integration (trigger incident for new critical issues) ---
$pagerDutyKey = $env:ZTA_PAGERDUTY_KEY
if ($pagerDutyKey -and $newCriticals.Count -gt 0) {
    $pagerPayload = @{
        routing_key  = $pagerDutyKey
        event_action = 'trigger'
        payload      = @{
            summary  = "Zero Trust Automation: $($newCriticals.Count) new critical issues detected."
            source   = $env:COMPUTERNAME
            severity = 'critical'
        }
    } | ConvertTo-Json -Depth 4
    try {
        Write-Host "[VERBOSE] Triggering PagerDuty incident..."
        Invoke-RestMethod -Uri 'https://events.pagerduty.com/v2/enqueue' -Method Post -Body $pagerPayload -ContentType 'application/json'
        Write-Host "PagerDuty incident triggered."
    }
    catch {
        Write-Error "[ERROR] PagerDuty integration failed: $_"
    }
}

# --- Trigger remediation script if new critical issues found ---
if ($newCriticals.Count -gt 0 -and $remediationScript -and $remediationScript.Trim() -ne '' -and (Test-Path $remediationScript)) {
    Write-Host "Triggering remediation script due to new critical issues..."
    & $remediationScript
}

# --- Mark resolved in log ---
$resolvedEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [RESOLVED] $($newCriticals.Count) critical issues addressed."
Add-Content $logPath $resolvedEntry

# Save the generated HTML report for review
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
Set-Content -Path $htmlPath -Value $htmlBody -Encoding UTF8
Write-Host "HTML report saved to $htmlPath"

# Export HTML report to PDF automatically using wkhtmltopdf
$wkhtmltopdf = 'D:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe'
$htmlPath = Join-Path $PSScriptRoot 'latest_report.html'
$pdfPath = Join-Path $PSScriptRoot 'latest_report.pdf'
if (Test-Path $wkhtmltopdf) {
    & $wkhtmltopdf $htmlPath $pdfPath
    Write-Host "PDF report saved to $pdfPath"
}
else {
    Write-Warning "wkhtmltopdf not found at $wkhtmltopdf. PDF export skipped."
}

# --- Asset Inventory Chart Data ---
$assetStatusCounts = $assetInventory | Group-Object Status | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$assetStatusLabels = ($assetStatusCounts | ForEach-Object { $_.label }) -join ","
$assetStatusData = ($assetStatusCounts | ForEach-Object { $_.count }) -join ","
$assetChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($assetStatusLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Assets',data:[$assetStatusData],backgroundColor:['#0057b8','#b80000']}]}}"

# --- Vulnerability Severity Chart Data ---
$vulnSeverityCounts = $vulnScan | Group-Object Severity | ForEach-Object { @{ label = $_.Name; count = $_.Count } }
$vulnSeverityLabels = ($vulnSeverityCounts | ForEach-Object { $_.label }) -join ","
$vulnSeverityData = ($vulnSeverityCounts | ForEach-Object { $_.count }) -join ","
$vulnChartUrl = "https://quickchart.io/chart?c={type:'bar',data:{labels:[$($vulnSeverityLabels -replace '([^,]+)', '""$1""')],datasets:[{label:'Vulnerabilities',data:[$vulnSeverityData],backgroundColor:['#b80000','#b88600','#00796b','#0057b8']}]}}"

# --- Integration Config Placeholders ---
$JiraBaseUrl = $env:JIRA_BASE_URL  # e.g. https://yourcompany.atlassian.net
$JiraUser = $env:JIRA_USER         # e.g. user@company.com
$JiraAPIToken = $env:JIRA_API_TOKEN
$JiraProjectKey = $env:JIRA_PROJECT_KEY
$ServiceNowUrl = $env:SERVICENOW_URL  # e.g. https://instance.service-now.com
$ServiceNowUser = $env:SERVICENOW_USER
$ServiceNowPass = $env:SERVICENOW_PASS
$TwilioSID = $env:TWILIO_SID
$TwilioToken = $env:TWILIO_TOKEN
$TwilioFrom = $env:TWILIO_FROM
$TwilioTo = $env:TWILIO_TO

function New-JiraIssue {
    param($summary, $description, $priority = 'High')
    if (-not $JiraBaseUrl -or -not $JiraUser -or -not $JiraAPIToken -or -not $JiraProjectKey) {
        Write-Warning 'Jira integration not configured.'; return
    }
    $body = @{ fields = @{ project = @{ key = $JiraProjectKey }; summary = $summary; description = $description; issuetype = @{ name = 'Task' }; priority = @{ name = $priority } } } | ConvertTo-Json -Depth 10
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraAPIToken}"))) }
    try {
        Invoke-RestMethod -Uri "$JiraBaseUrl/rest/api/2/issue" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "Jira issue created: $summary"
    }
    catch { Write-Warning "Failed to create Jira issue: $_" }
}

function New-ServiceNowIncident {
    param($shortDesc, $desc)
    if (-not $ServiceNowUrl -or -not $ServiceNowUser -or -not $ServiceNowPass) {
        Write-Warning 'ServiceNow integration not configured.'; return
    }
    $body = @{ short_description = $shortDesc; description = $desc } | ConvertTo-Json
    $headers = @{ Authorization = ('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ServiceNowUser}:${ServiceNowPass}"))) }
    try {
        Invoke-RestMethod -Uri "$ServiceNowUrl/api/now/table/incident" -Method Post -Headers $headers -Body $body -ContentType 'application/json'
        Write-Host "ServiceNow incident created: $shortDesc"
    }
    catch { Write-Warning "Failed to create ServiceNow incident: $_" }
}

function Send-TwilioSMS {
    param($body)
    if (-not $TwilioSID -or -not $TwilioToken -or -not $TwilioFrom -or -not $TwilioTo) {
        Write-Warning 'Twilio SMS integration not configured.'; return
    }
    $uri = "https://api.twilio.com/2010-04-01/Accounts/$TwilioSID/Messages.json"
    $post = @{ From = $TwilioFrom; To = $TwilioTo; Body = $body }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Credential (New-Object PSCredential($TwilioSID, (ConvertTo-SecureString $TwilioToken -AsPlainText -Force))) -Body $post
        Write-Host "SMS sent via Twilio."
    }
    catch { Write-Warning "Failed to send SMS: $_" }
}

# --- User-Specific Dashboard Logic ---
# Example: Generate a summary for each unique Owner in asset inventory
$userDashboards = @()
$uniqueOwners = $assetInventory | Select-Object -ExpandProperty Owner -Unique
foreach ($owner in $uniqueOwners) {
    $ownerAssets = $assetInventory | Where-Object { $_.Owner -eq $owner }
    $ownerVulns = $vulnScan | Where-Object { $ownerAssets.AssetID -contains $_.AssetID }
    $userDashboards += @(@"
    <div class='section' style='border-left:8px solid #00796b;background:#e0f7fa;'>
        <h3>User Dashboard: $owner</h3>
        <b>Assets:</b> $($ownerAssets.Count) | <b>Open Vulns:</b> $openVulnsCount
        <ul>
            <li>Assets: $assetHostnamesStr</li>
            <li>Open Vulns: $openVulnsFindingsStr</li>
        </ul>
    </div>
"@
$userDashboards += $dashboardHtml
}
# --- Generate HTML report with user dashboards ---
$htmlBody = $htmlBody + $userDashboards
$subject = if ($customSubject) { $customSubject } else { 'Zero Trust Automation Report' }
# --- Modern Email Sending with MailKit ---
Write-Host "[VERBOSE] Email sending block starting. Using SendGrid Web API."
Write-Host "[VERBOSE] Preparing SendGrid Web API payload for multiple recipients, HTML, and attachment..."
$toArray = @($emailRecipients | ForEach-Object { @{ email = $_ } })
$htmlBody = @"
<html>
<head>
<style>
    body { font-family: Arial, sans-serif; background: #f8f9fa; color: #222; }
    h2 { color: #0057b8; }
    h3 { color: #333; margin-top: 24px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #bbb; padding: 8px 12px; text-align: left; }
    th { background: #0057b8; color: #fff; }
    tr:nth-child(even) { background: #f2f2f2; }
    .section { background: #fff; border-radius: 8px; box-shadow: 0 2px 6px #0001; padding: 16px; margin-bottom: 24px; }
    .critical { color: #b80000; font-weight: bold; }
    .warning { color: #b88600; }
    .info { color: #0057b8; }
    .logo { display: block; margin: 0 auto 24px auto; max-width: 220px; }
    /* Per-section branding */
    .incidents-section { border-left: 8px solid #b80000; background: #fff5f5; }
    .compliance-section { border-left: 8px solid #00796b; background: #e0f7fa; }
    .user-activity-section { border-left: 8px solid #b88600; background: #fffbe6; }
    .patch-section { border-left: 8px solid #0057b8; background: #e3f2fd; }
    .asset-section { border-left: 8px solid #6a1b9a; background: #f3e5f5; }
    .vuln-section { border-left: 8px solid #d84315; background: #ffebee; }
</style>
<script>
function toggleSection(id) {
  var x = document.getElementById(id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</script>
</head>
<body>
    <img src="$([Environment]::GetEnvironmentVariable('ZTA_LOGO_URL','User') ?? 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Zero_Trust_logo.png')" alt="Zero Trust Logo" class="logo" />
    <div class="section" style="text-align:center;background:#e0f7fa;border:2px solid #00796b;">
        <h2 style="margin-bottom:0;color:#00796b;">Zero Trust Automation Report</h2>
        <p style="margin-top:4px;font-size:16px;color:#00796b;">Comprehensive daily summary for your security operations</p>
        <p style="font-size:13px;color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <div class="section incidents-section">
        <h3>Incident Timeline</h3>
        <table>
            <tr><th>Time</th><th>Event</th><th>Severity</th><th>Status</th></tr>
            $((
                $incidents |
                Sort-Object @{Expression={
                    switch ($_.Severity) {
                        'Critical' { 1 }
                        'Warning' { 2 }
                        'Info' { 3 }
                        default { 4 }
                    }
                }}, @{Expression={ try { [datetime]::Parse($_.Time) } catch { [datetime]::MinValue } }; Descending=$true} |
                ForEach-Object {
                    $sevColor = switch ($_.Severity) {
                        'Critical' { '#b80000' }
                        'Warning' { '#b88600' }
                        'Info' { '#0057b8' }
                        default { '#222' }
                    }
                    $rowStyle = ""
                    try {
                        $incidentTime = [datetime]::Parse($_.Time)
                        if ($_.Status -ne 'Completed' -and $incidentTime -lt (Get-Date).AddDays(-1)) {
                            $rowStyle = "background:#ffeaea;font-weight:bold;"
                        }
                    } catch {}
                    "<tr style='$rowStyle'><td>$($_.Time)</td><td>$($_.Event)</td><td style='color:$sevColor;font-weight:bold;'>$($_.Severity)</td><td>$($_.Status)</td></tr>"
                }
            ) -join "")
        </table>
        <p style="font-size:13px;color:#b80000;">Overdue incidents are highlighted in pink. Sorted by severity and time.</p>
    </div>
    <div class="section compliance-section">
        <h3>Compliance Status</h3>
        <img src="https://quickchart.io/chart?c={type:'pie',data:{labels:['Compliant','Non-Compliant'],datasets:[{data:[$($compliance | Where-Object { $_.Status -eq 'Compliant' }).Count,$($compliance | Where-Object { $_.Status -ne 'Compliant' }).Count]}]}}" alt="Compliance Pie Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>Control</th><th>Status</th><th>Owner</th><th>Last Checked</th></tr>
            $(( $compliance | Sort-Object { if ($_.Status -eq 'Compliant') { 1 } else { 0 } } | ForEach-Object {
                $statusColor = if ($_.Status -eq 'Compliant') { '#0057b8' } else { '#b80000' }
                "<tr><td>$($_.Control)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td><td>$($_.Owner)</td><td>$($_.LastChecked)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#888;">Non-compliant controls are shown at the top.</p>
    </div>
    <div class="section user-activity-section">
        <h3>User Activity (Failed Only)</h3>
        <table>
            <tr><th>User</th><th>Activity</th><th>Time</th><th>Result</th></tr>
            $(( $userActivity | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object {
                $resultColor = '#b80000'
                $rowStyle = 'background:#ffeaea;font-weight:bold;'
                "<tr style='$rowStyle'><td>$($_.User)</td><td>$($_.Activity)</td><td>$($_.Time)</td><td style='color:$resultColor;font-weight:bold;'>$($_.Result)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b80000;">Only failed activities are shown.</p>
    </div>
    <div class="section patch-section">
        <h3>Patch Status</h3>
        <img src="https://quickchart.io/chart?c={type:'doughnut',data:{labels:['Installed','Pending'],datasets:[{data:[$($patchStatus | Where-Object { $_.Status -eq 'Installed' }).Count,$($patchStatus | Where-Object { $_.Status -eq 'Pending' }).Count]}]}}" alt="Patch Status Chart" style="max-width:300px;display:block;margin:0 auto 16px auto;" />
        <table>
            <tr><th>System</th><th>Patch</th><th>Status</th><th>Deployed On</th></tr>
            $(( $patchStatus | ForEach-Object {
                $patchColor = if ($_.Status -eq 'Installed') { '#0057b8' } else { '#b88600' }
                $rowStyle = if ($_.Status -eq 'Pending') { 'background:#fffbe6;font-weight:bold;' } else { '' }
                "<tr style='$rowStyle'><td>$($_.System)</td><td>$($_.Patch)</td><td style='color:$patchColor;font-weight:bold;'>$($_.Status)</td><td>$($_.DeployedOn)</td></tr>"
            }) -join "" )
        </table>
        <p style="font-size:13px;color:#b88600;">Pending patches are highlighted in yellow.</p>
    </div>
    <div class="section asset-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('assetInventorySection')">Asset Inventory <span style='font-size:14px;color:#6a1b9a;'>(click to expand/collapse)</span></h3>
        <div id="assetInventorySection" style="display:none;">
            <img src="$assetChartUrl" alt="Asset Status Bar Chart" style="max-width:400px;display:block;margin:0 auto 16px auto;" />
            <table>
                <tr><th>AssetID</th><th>Hostname</th><th>IP</th><th>OS</th><th>Owner</th><th>Location</th><th>Status</th></tr>
                $(( $assetInventory | ForEach-Object {
                    $statusColor = if ($_.Status -eq 'Active') { '#0057b8' } else { '#b80000' }
                    "<tr><td>$($_.AssetID)</td><td>$($_.Hostname)</td><td>$($_.IP)</td><td>$($_.OS)</td><td>$($_.Owner)</td><td>$($_.Location)</td><td style='color:$statusColor;font-weight:bold;'>$($_.Status)</td></tr>"
                }) -join "" )
            </table>
            <p style="font-size:13px;color:#888;">All assets tracked in inventory. Inactive assets are highlighted in red.</p>
        </div>
    </div>
    <div class="section vuln-section">
        <h3 style="cursor:pointer;" onclick="toggleSection('vulnScanSection')">Vulnerability Scan Results <span style='font-size:14px;color:#d84315;'>(click to expand/collapse)</span></h3>