<#
PowerShell sample for secure email sending via SendGrid Web API
Requires: SendGrid API key set as environment variable SENDGRID_API_KEY
#>

$to = 'jasonnorman66994@gmail.com'
$from = 'jasonnorman66994@gmail.com'
$subject = 'Archive Signed Test'
$body = 'This is a test email from your Zero Trust automation.'
$sendgridApiKey = $env:SENDGRID_API_KEY
$attachmentPath = "d:\zero-trust-architecture-main-all\sample_report.html"

if (-not $sendgridApiKey) {
    Write-Error "SENDGRID_API_KEY environment variable not set."
    exit 1
}

$personalizations = @(@{ to = @(@{ email = $to }); subject = $subject })
$content = @(
    @{ type = "text/plain"; value = $body },
    @{ type = "text/html"; value = $body }
)

$attachments = @()
if (Test-Path $attachmentPath) {
    $fileBytes = [System.IO.File]::ReadAllBytes($attachmentPath)
    $fileBase64 = [Convert]::ToBase64String($fileBytes)
    $attachments += @{
        content  = $fileBase64
        filename = [System.IO.Path]::GetFileName($attachmentPath)
        type     = "text/html"
    }
}

$payload = @{
    personalizations = $personalizations
    from             = @{ email = $from }
    content          = $content
}
if ($attachments.Count -gt 0) {
    $payload.attachments = $attachments
}

$payloadJson = $payload | ConvertTo-Json -Depth 6
$headers = @{ "Authorization" = "Bearer $sendgridApiKey"; "Content-Type" = "application/json" }

try {
    $response = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $payloadJson
    Write-Host "Email sent successfully via SendGrid API."
}
catch {
    Write-Error "Failed to send email via SendGrid API: $_"
}
