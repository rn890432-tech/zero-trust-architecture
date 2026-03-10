<# Track script execution time #>
# $startTime = Get-Date
# Ensure YAML module is available
try {
    Import-Module powershell-yaml -Force -ErrorAction Stop
}
catch {
    # Try importing from explicit versioned .psm1 file if not found
    $possiblePaths = @(
        "$env:USERPROFILE\\OneDrive\\Documents\\PowerShell\\Modules\\powershell-yaml\\0.4.12\\powershell-yaml.psm1",
        "$env:USERPROFILE\\Documents\\PowerShell\\Modules\\powershell-yaml\\0.4.12\\powershell-yaml.psm1"
    )
    $imported = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Import-Module $path -Force
            $imported = $true
            break
        }
    }
    if (-not $imported) {
        Write-Warning "powershell-yaml module not available or in use. Continuing without YAML export."
    }
}



# --- Set forgiving defaults for required parameters ---
if (-not $To) { $To = @("admin@example.com") }
if (-not $From) { $From = "admin@example.com" }
if (-not $Subject) { $Subject = "Zero Trust Audit Report" }
if (-not $SmtpServer) { $SmtpServer = "smtp.example.com" }
if (-not $ReportPath) { $ReportPath = "$PSScriptRoot\latest_report.html" }
if (-not $Date) { $Date = (Get-Date -Format 'yyyy-MM-dd') }
if (-not $Summary) { $Summary = "All systems operational" }
if (-not $Details) { $Details = @(@{Check = "Firewall"; Status = "pass"; Details = "No issues" }) }
if (-not $AdminEmail) { $AdminEmail = "admin@example.com" }
if (-not $ArchiveDir) { $ArchiveDir = "$PSScriptRoot\archives" }
if (-not $MaxRetries) { $MaxRetries = 3 }
if (-not $RetryDelaySeconds) { $RetryDelaySeconds = 10 }

# --- Load recipients from CSV if $To is not provided ---
if (-not $To -or $To.Count -eq 0) {
    $recipientsCsv = Join-Path $PSScriptRoot 'automation\email_recipients.csv'
    if (Test-Path $recipientsCsv) {
        $emailConfig = Import-Csv $recipientsCsv
        $allRow = $emailConfig | Where-Object { $_.Section -eq 'ALL' }
        if ($allRow -and $allRow.Recipients) {
            $To = $allRow.Recipients -split ',' | ForEach-Object { $_.Trim() }
        }
    }
}

# Helper function to trigger integrations based on report content
function Invoke-Integrations {
    param(
        [array]$Details,
        [string]$JiraUrl,
        [string]$JiraProjectKey,
        [string]$JiraIssueType,
        [string]$JiraUsername,
        [string]$JiraApiToken,
        [string]$ServiceNowUrl,
        [string]$ServiceNowUsername,
        [SecureString]$ServiceNowPassword,
        [string]$SplunkHECUrl,
        [string]$SplunkHECToken,
        [string]$PagerDutyRoutingKey,
        [string]$PagerDutySource,
        [string]$GitHubRepoOwner,
        [string]$GitHubRepoName,
        [string]$GitHubToken
    )
    $criticalFindings = $Details | Where-Object { $_.Status -imatch 'fail|critical|unauthorized|error' }
    if ($criticalFindings.Count -gt 0) {
        $summary = "Critical findings detected in Zero Trust Audit Report"
        $desc = ($criticalFindings | ForEach-Object { "- $($_.Check): $($_.Details)" }) -join "`n"
        if ($JiraUrl -and $JiraProjectKey -and $JiraUsername -and $JiraApiToken) {
            & "$PSScriptRoot\create_jira_issue.ps1" -Summary $summary -Description $desc -JiraUrl $JiraUrl -ProjectKey $JiraProjectKey -IssueType $JiraIssueType -Username $JiraUsername -ApiToken $JiraApiToken
        }
        if ($ServiceNowUrl -and $ServiceNowUsername -and $ServiceNowPassword) {
            & "$PSScriptRoot\create_servicenow_incident.ps1" -ShortDescription $summary -Description $desc -ServiceNowUrl $ServiceNowUrl -Username $ServiceNowUsername -Password $ServiceNowPassword
        }
        if ($SplunkHECUrl -and $SplunkHECToken) {
            $eventJson = @{ summary = $summary; details = $criticalFindings } | ConvertTo-Json -Depth 10
            & "$PSScriptRoot\send_to_splunk.ps1" -SplunkHECUrl $SplunkHECUrl -HECToken $SplunkHECToken -EventJson $eventJson
        }
        if ($PagerDutyRoutingKey -and $PagerDutySource) {
            & "$PSScriptRoot\send_pagerduty_alert.ps1" -RoutingKey $PagerDutyRoutingKey -Summary $summary -Source $PagerDutySource
        }
        if ($GitHubRepoOwner -and $GitHubRepoName -and $GitHubToken) {
            & "$PSScriptRoot\create_github_issue.ps1" -RepoOwner $GitHubRepoOwner -RepoName $GitHubRepoName -Title $summary -Body $desc -GitHubToken $GitHubToken
        }
    }
}




# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMsg = "[$timestamp] $Message"
    Write-Host $logMsg
    Add-Content -Path "$PSScriptRoot\automation_log.txt" -Value $logMsg
}

# Slack/Teams notification function
function Send-WebhookNotification {
    param(
        [string]$Message,
        [string]$SlackUrl = $null,
        [string]$TeamsUrl = $null
    )
    if ($SlackUrl) {
        try {
            $payload = @{ text = $Message } | ConvertTo-Json
            Invoke-RestMethod -Uri $SlackUrl -Method Post -ContentType 'application/json' -Body $payload | Out-Null
            Write-Log "Sent Slack notification."
        }
        catch {
            Write-Log "WARNING: Failed to send Slack notification: $_"
        }
    }
    if ($TeamsUrl) {
        try {
            $payload = @{ text = $Message } | ConvertTo-Json
            Invoke-RestMethod -Uri $TeamsUrl -Method Post -ContentType 'application/json' -Body $payload | Out-Null
            Write-Log "Sent Teams notification."
        }
        catch {
            Write-Log "WARNING: Failed to send Teams notification: $_"
        }
    }
}

# Error notification function
function Send-ErrorNotification {
    param(
        [string]$ErrorMessage
    )
    if ($AdminEmail) {
        $subject = "[ALERT] Automation Error Notification"
        $body = "An error occurred during the automation process:`n`n$ErrorMessage`n`nSee automation_log.txt for details."
        $bodyFile = "$env:TEMP\error_email_body.txt"
        Set-Content -Path $bodyFile -Value $body
        # Ensure Password is a SecureString
        $securePass = $null
        if ($Password -is [string]) {
            $securePass = ConvertTo-SecureString $Password -AsPlainText -Force
        } elseif ($Password -is [System.Security.SecureString]) {
            $securePass = $Password
        }
        & "$PSScriptRoot\send-custom-email.ps1" -To $AdminEmail -From $From -Subject $subject -SmtpServer $SmtpServer -BodyFile $bodyFile -Attachment "$PSScriptRoot\automation_log.txt" @{
            Password         = $securePass
            CredentialTarget = $CredentialTarget
        }
    }
}

# Load config file if present, resolve env vars, and load credentials
function Resolve-EnvVars {
    param([string]$value)
    if ($value -match '\$\{([A-Za-z0-9_]+)\}') {
        $envVar = $matches[1]
        $envValue = [Environment]::GetEnvironmentVariable($envVar)
        if ($envValue) { return $envValue } else { return $value }
    }
    return $value
}

    if ($ConfigFile -and ($ConfigFile.Trim() -ne "") -and (Test-Path $ConfigFile)) {
        try {
            $config = ConvertFrom-Yaml -Yaml (Get-Content $ConfigFile -Raw)
            foreach ($key in $config.PSObject.Properties.Name) {
                $val = $config.$key
                if ($val -is [string]) { $config.$key = Resolve-EnvVars $val }
            }
            if (-not $From -and $config.from) { $From = $config.from }
            if (-not $SmtpServer -and $config.smtp_server) { $SmtpServer = $config.smtp_server }
            if (-not $CredentialTarget -and $config.credential_target) { $CredentialTarget = $config.credential_target }
            if (-not $AdminEmail -and $config.admin_email) { $AdminEmail = $config.admin_email }
            if (-not $ArchiveDir -and $config.archive_dir) { $ArchiveDir = $config.archive_dir }
            if (-not $SlackWebhookUrl -and $config.slack_webhook_url) { $SlackWebhookUrl = $config.slack_webhook_url }
            if (-not $TeamsWebhookUrl -and $config.teams_webhook_url) { $TeamsWebhookUrl = $config.teams_webhook_url }
            if (-not $AzureBlobConnectionString -and $config.azure_blob_connection_string) { $AzureBlobConnectionString = $config.azure_blob_connection_string }
            if (-not $AzureBlobContainer -and $config.azure_blob_container) { $AzureBlobContainer = $config.azure_blob_container }
            if (-not $S3Bucket -and $config.s3_bucket) { $S3Bucket = $config.s3_bucket }
            if (-not $S3KeyPrefix -and $config.s3_key_prefix) { $S3KeyPrefix = $config.s3_key_prefix }
            if ($config.google_drive_upload) { $GoogleDriveUpload = $true }
            # Ensure GoogleDriveUpload is used
            $null = $GoogleDriveUpload
            # Integration params
            if ($config.jira_url) { $JiraUrl = $config.jira_url }
            if ($config.jira_project_key) { $JiraProjectKey = $config.jira_project_key }
            if ($config.jira_issue_type) { $JiraIssueType = $config.jira_issue_type }
            if ($config.jira_username) { $JiraUsername = $config.jira_username }
            if ($config.jira_api_token) { $JiraApiToken = $config.jira_api_token }
            if ($config.servicenow_url) { $ServiceNowUrl = $config.servicenow_url }
            if ($config.servicenow_username) { $ServiceNowUsername = $config.servicenow_username }
            if ($config.servicenow_password) { $ServiceNowPassword = $config.servicenow_password | ConvertTo-SecureString -AsPlainText -Force }
            if ($config.splunk_hec_url) { $SplunkHECUrl = $config.splunk_hec_url }
            if ($config.splunk_hec_token) { $SplunkHECToken = $config.splunk_hec_token }
        }
        catch {
            Write-Log "WARNING: Failed to load config file: $_"
        }
    }

    # Load password from Windows Credential Manager if CredentialTarget is set and Password is not
    if ($CredentialTarget -and -not $Password) {
        try {
            $cred = Get-StoredCredential -Target $CredentialTarget
            if ($cred) {
                $Password = $cred.Password | ConvertTo-SecureString -AsPlainText -Force
                if (-not $From -and $cred.UserName) { $From = $cred.UserName }
            }
        }
        catch {
            Write-Log "WARNING: Could not load credentials from Windows Credential Manager: $_"
        }
    }

    # Parameter validation and recipient loading
    if (-not $To -or $To.Count -eq 0) {
        # Try to load recipients from automation/email_recipients.csv
        $recipientsCsvPath = "$PSScriptRoot\automation\email_recipients.csv"
        if (Test-Path $recipientsCsvPath) {
            $emailConfig = Import-Csv $recipientsCsvPath
            $allRow = $emailConfig | Where-Object { $_.Section -eq 'ALL' }
            if ($allRow -and $allRow.Recipients) {
                $To = $allRow.Recipients -split ',' | ForEach-Object { $_.Trim() }
            }
        }
    }
    if (-not $To -or $To.Count -eq 0) {
        $errMsg = "ERROR: At least one recipient is required."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    foreach ($recipient in $To) {
        if (-not ($recipient -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')) {
            $errMsg = "ERROR: Invalid recipient email address: $recipient"
            Write-Log $errMsg
            Send-ErrorNotification $errMsg
            exit 1
        }
    }
    if (-not $From -or -not ($From -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')) {
        $errMsg = "ERROR: Valid sender email address is required."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    if (-not $ReportPath) {
        $errMsg = "ERROR: ReportPath is required."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    if (-not $Date) {
        $errMsg = "ERROR: Date is required."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    if (-not $Summary) {
        $errMsg = "ERROR: Summary is required."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    if (-not $Details -or $Details.Count -eq 0) {
        $errMsg = "ERROR: Details array is required and cannot be empty."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }

    Write-Log "Starting report generation for $To."
    Write-Log "Generating report."
    & "$PSScriptRoot\generate_dynamic_report.ps1" -ReportPath $ReportPath -Date $Date -Summary $Summary -Details $Details
    if ($LASTEXITCODE -ne 0) {
        $errMsg = "ERROR: Report generation failed."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }

    Write-Log "Report generated at $ReportPath."

    # Trigger integrations if critical findings
    Invoke-Integrations -Details $Details \
    -JiraUrl $JiraUrl -JiraProjectKey $JiraProjectKey -JiraIssueType $JiraIssueType -JiraUsername $JiraUsername -JiraApiToken $JiraApiToken \
    -ServiceNowUrl $ServiceNowUrl -ServiceNowUsername $ServiceNowUsername -ServiceNowPassword $ServiceNowPassword \
    -SplunkHECUrl $SplunkHECUrl -SplunkHECToken $SplunkHECToken \
    -PagerDutyRoutingKey $PagerDutyRoutingKey -PagerDutySource $PagerDutySource \
    -GitHubRepoOwner $GitHubRepoOwner -GitHubRepoName $GitHubRepoName -GitHubToken $GitHubToken

    # Generate chart and attach (modular)
    $chartPath = "$env:TEMP\report_chart.png"
    & "$PSScriptRoot\generate_chart.ps1" -Details $Details -ChartPath $chartPath
    if (Test-Path $chartPath) {
        $Attachments += $chartPath
        Write-Log "Chart attached: $chartPath"
    }
    if ($LASTEXITCODE -ne 0) {
        $errMsg = "ERROR: Report generation failed."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    Write-Log "Report generated at $ReportPath."


    # Prepare email body from template (supports {Date} and {Summary} replacement)
    if (Test-Path $EmailBodyTemplate) {
        $emailBody = Get-Content $EmailBodyTemplate -Raw
        $emailBody = $emailBody -replace "\{Date\}", $Date -replace "\{Summary\}", $Summary
    }
    else {
        $emailBody = "Hello,`n`nPlease find attached the latest Security Audit Report generated on $Date.`n`nSummary: $Summary`n`nRegards,`nZero Trust Automation System"
    }
    $emailBodyFile = "$env:TEMP\email_body.txt"
    Set-Content -Path $emailBodyFile -Value $emailBody
    Write-Log "Email body prepared at $emailBodyFile."

    # Send the email (support multiple recipients and attachments)
    Write-Log "Sending email to $($To -join ', ')."
    # Ensure Password is a SecureString
    $securePass = $null
    if ($Password -is [string]) {
        $securePass = ConvertTo-SecureString $Password -AsPlainText -Force
    } elseif ($Password -is [System.Security.SecureString]) {
        $securePass = $Password
    }
    & "$PSScriptRoot\send-custom-email.ps1" -To ($To -join ',') -From $From -Subject $Subject -SmtpServer $SmtpServer -BodyFile $emailBodyFile -Attachment ($Attachments + $ReportPath -join ',') @{
        Password         = $securePass
        CredentialTarget = $CredentialTarget
    }
    if ($LASTEXITCODE -ne 0) {
        $errMsg = "ERROR: Email sending failed."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }


    # Execution summary start time



function Invoke-RetryOperation {
    param(
        [scriptblock]$Command,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 10
    )
    $attempt = 1
    while ($attempt -le $MaxAttempts) {
        try {
            & $Command
            if ($LASTEXITCODE -eq 0) { return $true }
        }
        catch {
            Write-Log "Attempt $attempt failed: $_"
        }
        if ($attempt -lt $MaxAttempts) {
            Write-Log "Retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
        $attempt++
    }
    return $false
}

# Send the email (support multiple recipients and attachments) with retry logic
Write-Log "Sending email to $($To -join ', ')."
$sendEmailCmd = {
    & "$PSScriptRoot\send-custom-email.ps1" -To ($To -join ',') -From $From -Subject $Subject -SmtpServer $SmtpServer -BodyFile $emailBodyFile -Attachment ($Attachments + $ReportPath -join ',') @{
        Password         = $Password
        CredentialTarget = $CredentialTarget
    }
}
$emailSuccess = Invoke-RetryOperation -Command $sendEmailCmd -MaxAttempts $MaxRetries -DelaySeconds $RetryDelaySeconds
if (-not $emailSuccess) {
    $errMsg = "ERROR: Email sending failed after $MaxRetries attempts."
    Write-Log $errMsg
    Send-ErrorNotification $errMsg
    exit 1
}

Write-Log "Report generated and emailed to $($To -join ', ')."
Write-Host "Report generated and emailed to $($To -join ', ')."
Send-WebhookNotification -Message "[SUCCESS] Automation report sent to $($To -join ', ') on $Date." -SlackUrl $SlackWebhookUrl -TeamsUrl $TeamsWebhookUrl


# Report encryption (GPG)
if ($EncryptReport -and $GpgRecipient) {
    $encryptedReportPath = "$ReportPath.gpg"
    $gpgCmd = "gpg --yes --batch --output `"$encryptedReportPath`" --encrypt --recipient `"$GpgRecipient`" `"$ReportPath`""
    Write-Log "Encrypting report with GPG for recipient $GpgRecipient."
    Invoke-Expression $gpgCmd
    if (!(Test-Path $encryptedReportPath)) {
        $errMsg = "ERROR: Report encryption failed."
        Write-Log $errMsg
        Send-ErrorNotification $errMsg
        exit 1
    }
    $ReportPath = $encryptedReportPath
    Write-Log "Report encrypted to $ReportPath."
}

# Success notification to admin
if ($AdminEmail) {
    $successSubject = "[SUCCESS] Automation Report Sent"
    $successBody = "The automation process completed successfully.\n\nReport sent to: $($To -join ', ')\nDate: $Date\nSummary: $Summary\n\nSee attached report and log."
    $successBodyFile = "$env:TEMP\success_email_body.txt"
    Set-Content -Path $successBodyFile -Value $successBody
    & "$PSScriptRoot\send-custom-email.ps1" -To $AdminEmail -From $From -Subject $successSubject -SmtpServer $SmtpServer -BodyFile $successBodyFile -Attachment ("$ReportPath,$PSScriptRoot\automation_log.txt") @{
        Password         = $Password
        CredentialTarget = $CredentialTarget
    }
    Write-Log "Success notification sent to admin: $AdminEmail."
}


# Archive report and log
if (!(Test-Path $ArchiveDir)) {
    New-Item -Path $ArchiveDir -ItemType Directory | Out-Null
}
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ($ReportPath -like '*.gpg') {
    $reportExt = 'html.gpg'
}
else {
    $reportExt = 'html'
}
$reportArchive = Join-Path $ArchiveDir ("report_$timestamp.$reportExt")
$logArchive = Join-Path $ArchiveDir ("automation_log_$timestamp.txt")
Copy-Item -Path $ReportPath -Destination $reportArchive -Force
Copy-Item -Path "$PSScriptRoot\automation_log.txt" -Destination $logArchive -Force
if (Test-Path $chartPath) { Copy-Item -Path $chartPath -Destination (Join-Path $ArchiveDir ("chart_$timestamp.png")) -Force }
Write-Log "Archived report to $reportArchive and log to $logArchive."

# Upload to cloud providers using modular scripts
$cloudLinks = @()
if ($AzureBlobConnectionString -and $AzureBlobContainer) {
    $cloudLinks += & "$PSScriptRoot\upload_to_azure_blob.ps1" -FilePath $reportArchive -ConnectionString $AzureBlobConnectionString -Container $AzureBlobContainer
    $cloudLinks += & "$PSScriptRoot\upload_to_azure_blob.ps1" -FilePath $logArchive -ConnectionString $AzureBlobConnectionString -Container $AzureBlobContainer
    if (Test-Path $chartPath) {
        $cloudLinks += & "$PSScriptRoot\upload_to_azure_blob.ps1" -FilePath $chartPath -ConnectionString $AzureBlobConnectionString -Container $AzureBlobContainer
    }
}
if ($S3Bucket -and $S3KeyPrefix) {
    $cloudLinks += & "$PSScriptRoot\upload_to_s3.ps1" -FilePath $reportArchive -Bucket $S3Bucket -Key ("$S3KeyPrefix/report_$timestamp.$reportExt")
    $cloudLinks += & "$PSScriptRoot\upload_to_s3.ps1" -FilePath $logArchive -Bucket $S3Bucket -Key ("$S3KeyPrefix/automation_log_$timestamp.txt")
    if (Test-Path $chartPath) {
        $cloudLinks += & "$PSScriptRoot\upload_to_s3.ps1" -FilePath $chartPath -Bucket $S3Bucket -Key ("$S3KeyPrefix/chart_$timestamp.png")
    }
}
if ($GoogleDriveUpload) {
    $cloudLinks += & "$PSScriptRoot\upload_to_google_drive.ps1" -FilePath $reportArchive
    $cloudLinks += & "$PSScriptRoot\upload_to_google_drive.ps1" -FilePath $logArchive
    if (Test-Path $chartPath) {
        $cloudLinks += & "$PSScriptRoot\upload_to_google_drive.ps1" -FilePath $chartPath
    }
}

# Log/archive cleanup (keep only last 30 days)
$now = Get-Date
$maxAge = (New-TimeSpan -Days 30)
Get-ChildItem -Path $ArchiveDir -File | Where-Object { ($now - $_.LastWriteTime) -gt $maxAge } | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Log "Deleted old archive: $($_.FullName)"
}

# Execution summary
$endTime = Get-Date
# Removed unused variable $startTime and related summary lines
$summary += "End Time: $($endTime.ToString('u'))" # Removed unused variable $startTime
$summary += "Duration: $($duration.ToString())"
$summary += "Recipients: $($To -join ', ')"
$summary += "Admin Notified: $AdminEmail"
$summary += "Report Path: $reportArchive"
$summary += "Log Path: $logArchive"
if ($cloudLinks.Count -gt 0) {
    $summary += "Cloud Links: $($cloudLinks -join ', ')"
}
Write-Host ($summary -join "`n")
Write-Log ($summary -join " | ")

# Include cloud links in notifications
if ($cloudLinks.Count -gt 0) {
    $cloudMsg = "Cloud Links: `n$($cloudLinks -join "`n")"
    Send-WebhookNotification -Message $cloudMsg -SlackUrl $SlackWebhookUrl -TeamsUrl $TeamsWebhookUrl
    # Optionally, include in admin email body as well
    if ($AdminEmail) {
        Add-Content -Path $successBodyFile -Value "`n`n$cloudMsg"
    }
}

# --- Execution summary and duration logging ---
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Log "Script execution duration: $duration"
