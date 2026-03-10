

# Set credentials and webhook securely (prompt for password)
$global:ZTA_EMAIL_USER = "jasonnorman66994@outlook.com"
$global:ZTA_EMAIL_PASS = Read-Host -AsSecureString "Enter email password for $($global:ZTA_EMAIL_USER) (input hidden)"
$global:ZTA_EMAIL_TO = "jasonnorman66994@gmail.com,jasonnorman66994@outlook.com,example1@email.com,example2@email.com,another@email.com,teamlead@email.com,security@email.com,admin@email.com,ops@email.com,alerts@email.com,alice@email.com,bob@email.com,charlie@email.com,dave@email.com,ellen@email.com,jasonnorman66994,janedoe@email.com,securityteam@email.com,alerts2@email.com,helpdesk@email.com"
$global:ZTA_SLACK_WEBHOOK = "https://hooks.slack.com/services/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"

# Change to the project directory
Set-Location "D:\zero-trust-architecture-main-all"

# Ensure working directory is correct before running notification script
Set-Location 'D:\zero-trust-architecture-main-all'
& 'D:\zero-trust-architecture-main-all\automation_notify.ps1'
