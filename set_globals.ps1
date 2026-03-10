# Set global variables for automation_notify.ps1

$global:ZTA_EMAIL_USER = "jasonnorman66994@gmail.com"
$global:ZTA_EMAIL_PASS = Read-Host -AsSecureString "Enter email password for $($global:ZTA_EMAIL_USER) (input hidden)"
$global:ZTA_EMAIL_TO = "jasonnorman66994@gmail.com"
$global:ZTA_SLACK_WEBHOOK = "https://hooks.slack.com/services/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"

Write-Host "Global variables set for automation_notify.ps1."
