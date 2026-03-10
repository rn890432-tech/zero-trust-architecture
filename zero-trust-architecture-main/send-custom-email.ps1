param(
    [Parameter(Mandatory = $true)]
    [string]$To,
    [Parameter(Mandatory = $true)]
    [string]$From,
    [Parameter(Mandatory = $true)]
    [string]$Subject,
    [Parameter(Mandatory = $true)]
    [string]$SmtpServer,
    [Parameter(Mandatory = $false)]
    [SecureString]$Password,
    [Parameter(Mandatory = $false)]
        [SecureString]$CredentialTarget,
    [Parameter(Mandatory = $true)]
    [string]$BodyFile,
    [Parameter(Mandatory = $false)]
    [string]$Attachment
)

# Read email body from file
if (Test-Path $BodyFile) {
    $Body = Get-Content $BodyFile -Raw
} else {
    Write-Error "Body file not found: $BodyFile"
    exit 1
}

# Get credentials
if ($CredentialTarget) {
    # Use Windows Credential Manager
    try {
        $Cred = Get-StoredCredential -Target $CredentialTarget
        if (-not $Cred) {
            Write-Error "No credentials found in Windows Credential Manager for target: $CredentialTarget"
            exit 1
        }
        $Credential = New-Object System.Management.Automation.PSCredential($Cred.UserName, ($Cred.Password | ConvertTo-SecureString -AsPlainText -Force))
    } catch {
        Write-Error "Failed to retrieve credentials from Windows Credential Manager. $_"
        exit 1
    }
} elseif ($Password) {
    # Use provided SecureString password
    $Credential = New-Object System.Management.Automation.PSCredential($From, $Password)
} else {
    Write-Error "Either -Password (as SecureString) or -CredentialTarget (Credential Manager) must be provided."
    exit 1
}

# Send the email
Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $SmtpServer -Port 587 -UseSsl -Credential $Credential -Attachments $Attachment

Write-Host "Email sent to $To with subject '$Subject' and attachment '$Attachment'"
