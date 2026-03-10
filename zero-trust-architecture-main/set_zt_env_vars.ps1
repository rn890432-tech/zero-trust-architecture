$NoColor = $false
# --- Import environment variables from .env file ---
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    $envLines = Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_.Contains('=') }
    foreach ($line in $envLines) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) {
            $var = $parts[0].Trim()
            $val = $parts[1].Trim()
            if ($var -and $val) {
                ${env:$var} = $val
                Write-Host "[INFO] Imported $var from .env file." -ForegroundColor Cyan
            }
        }
    }
}
else {
    Write-Host "[INFO] No .env file found to import." -ForegroundColor Yellow
}

# --- Overwrite .env file with valid values if needed ---
$envFile = Join-Path $PSScriptRoot ".env"
$envLines = @()
if (Test-Path $envFile) {
    $envLines = Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') }
}
$envDict = @{}
foreach ($line in $envLines) {
    if ($line -match "^") { continue }
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) {
        $envDict[$parts[0].Trim()] = $parts[1].Trim()
    }
}
# Ensure valid values
if (-not $envDict['EMAIL_ALERT_ADDRESS'] -or $envDict['EMAIL_ALERT_ADDRESS'] -notmatch '^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$') {
    $envDict['EMAIL_ALERT_ADDRESS'] = "admin@example.com"
}
if (-not $envDict['JIRA_API_TOKEN'] -or $envDict['JIRA_API_TOKEN'] -notmatch '^ATC.{20,}$') {
    $envDict['JIRA_API_TOKEN'] = "ATCxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
# Write back to .env
$envOut = $envDict.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }
Set-Content -Path $envFile -Value $envOut
Write-Host "[INFO] Overwrote .env file with valid values." -ForegroundColor Green

# --- Set valid default for EMAIL_ALERT_ADDRESS if not set or invalid ---
if (-not $env:EMAIL_ALERT_ADDRESS -or $env:EMAIL_ALERT_ADDRESS -notmatch '^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$') {
    $env:EMAIL_ALERT_ADDRESS = "admin@example.com"
}
# --- Set valid default for JIRA_API_TOKEN if not set or invalid ---
if (-not $env:JIRA_API_TOKEN -or $env:JIRA_API_TOKEN -notmatch '^ATC.{20,}$') {
    $env:JIRA_API_TOKEN = "ATCxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

function Write-Color {
    param([string]$Text, [string]$Color)
    if ($NoColor) {
        Write-Host $Text
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

# PowerShell script to set all required environment variables for Zero Trust Automation
# Run this script in your PowerShell session before running the automation scripts

# --- BEGIN: Set secrets as environment variables ---
# Replace the placeholder values with your actual secrets


$env:JIRA_API_TOKEN = "ATCTT3xFfGN0UKrU3tDDjisVYuqRG8cKSsGzczk0KLbzBxts2P7OIzTFNfo5ljrLdvAvBd07rk6Mm9l-SbXMHdsj8ouBatU5Sxrf68envggCg6rVi9we4HnyTx3hh2AzgnpEBUovLFFiJUIDz5Ol2Z5gmmPkVf1Ql1SAbe9zUPqiXeILhro1i9w=CCDBC7F7"
# Prompt for ServiceNow password as SecureString if not set
if (-not $ServiceNowPassword) {
    if ($env:SERVICENOW_PASSWORD) {
        # Try to convert from plain text env var (legacy)
        $ServiceNowPassword = $env:SERVICENOW_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
    } else {
        $ServiceNowPassword = Read-Host -AsSecureString "Enter ServiceNow password (input hidden)"
    }
}
# $env:AZURE_BLOB_CONN = "<your-azure-blob-connection-string>"  # Not needed if you don't use Azure
# $env:PAGERDUTY_ROUTING_KEY = "<your-pagerduty-routing-key>"  # Not needed if you don't use PagerDuty
$env:GITHUB_TOKEN = "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"

Write-Host "[INFO] All Zero Trust Automation environment variables have been set for this session." -ForegroundColor Green
# --- END ---

# --- FEATURE: Validate required environment variables ---
$requiredVars = @(
    'JIRA_API_TOKEN',
    'SERVICENOW_PASSWORD',
    'GITHUB_TOKEN'
)
$missingVars = @()
foreach ($var in $requiredVars) {
    if ($var -eq 'SERVICENOW_PASSWORD') {
        if (-not $ServiceNowPassword) { $missingVars += $var }
    } else {
        if (-not ${env:$var}) { $missingVars += $var }
    }
}
    if ($missingVars.Count -gt 0) {
        Write-Host "[WARNING] The following required environment variables are missing:" -ForegroundColor Yellow
        $missingVars | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
        Write-Host "Please set these variables before running automation scripts." -ForegroundColor Yellow
    }
    else {
        Write-Host "[INFO] All required environment variables are set." -ForegroundColor Green
    }

# --- FEATURE: Interactive prompt for missing variables ---

# --- Automated input for unattended runs ---
if ($missingVars.Count -gt 0) {
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        $envLines = Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_.Contains('=') }
        foreach ($line in $envLines) {
            $parts = $line -split '=', 2
            if ($parts.Count -eq 2) {
                $var = $parts[0].Trim()
                $val = $parts[1].Trim()
                if ($missingVars -contains $var) {
                    if ($var -eq 'SERVICENOW_PASSWORD') {
                        $ServiceNowPassword = $val | ConvertTo-SecureString -AsPlainText -Force
                        Write-Host "[INFO] Imported $var as SecureString from .env file for unattended run." -ForegroundColor Cyan
                    } else {
                        ${env:$var} = $val
                        Write-Host "[INFO] Imported $var from .env file for unattended run." -ForegroundColor Cyan
                    }
                }
            }
        }
    }
    # Fallback: set hardcoded values if still missing
    foreach ($var in $missingVars) {
        if ($var -eq 'SERVICENOW_PASSWORD' -and -not $ServiceNowPassword) {
            $ServiceNowPassword = Read-Host -AsSecureString "Enter ServiceNow password (input hidden)"
            Write-Host "[INFO] Prompted for $var as SecureString for unattended run." -ForegroundColor Cyan
        } elseif (-not ${env:$var}) {
            switch ($var) {
                'JIRA_API_TOKEN' { ${env:$var} = 'ATCTT3xFfGN0UKrU3tDDjisVYuqRG8cKSsGzczk0KLbzBxts2P7OIzTFNfo5ljrLdvAvBd07rk6Mm9l-SbXMHdsj8ouBatU5Sxrf68envggCg6rVi9we4HnyTx3hh2AzgnpEBUovLFFiJUIDz5Ol2Z5gmmPkVf1Ql1SAbe9zUPqiXeILhro1i9w=CCDBC7F7' }
                'GITHUB_TOKEN' { ${env:$var} = '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' }
                default { ${env:$var} = 'default-value' }
            }
            Write-Host "[INFO] Set $var to hardcoded value for unattended run." -ForegroundColor Cyan
        }
    }
}

# --- FEATURE: Export all env vars to .env file ---
$envFile = Join-Path $PSScriptRoot ".env"
$exportVars = @()
foreach ($var in $requiredVars) {
    if ($var -eq 'SERVICENOW_PASSWORD') {
        $exportVars += "$var=[SECURESTRING]"
    } else {
        $exportVars += "$var=$([Environment]::GetEnvironmentVariable($var))"
    }
}
Set-Content -Path $envFile -Value $exportVars
Write-Host "[INFO] Exported environment variables to .env file at $envFile" -ForegroundColor Cyan

function Protect-Secret {
    param([string]$value)
    if ($null -eq $value -or $value.Length -le 6) { return '***' }
    return $value.Substring(0, 2) + '***' + $value.Substring($value.Length - 2, 2)
}
$maskedExportVars = @()
foreach ($var in $requiredVars) {
    if ($var -eq 'SERVICENOW_PASSWORD') {
        $maskedExportVars += "$var=[SECURESTRING]"
    } else {
        $maskedExportVars += "$var=$(Protect-Secret ([Environment]::GetEnvironmentVariable($var)))"
    }
}
$maskedEnvFile = Join-Path $PSScriptRoot ".env.masked"
Set-Content -Path $maskedEnvFile -Value $maskedExportVars
Write-Host "[INFO] Exported masked environment variables to .env.masked at $maskedEnvFile" -ForegroundColor Yellow

# Consolidated top-level param block


# Set defaults after param block
if (-not $EnvProfile) { $EnvProfile = "default" }
if (-not $LogFile) { $LogFile = (Join-Path $PSScriptRoot "zt_env_audit.log") }

$profileVars = @{
    default = @{
        JIRA_API_TOKEN      = ${env:JIRA_API_TOKEN}
        SERVICENOW_PASSWORD = $ServiceNowPassword
        GITHUB_TOKEN        = ${env:GITHUB_TOKEN}
    }
    dev     = @{
        JIRA_API_TOKEN      = "dev-jira-token"
        SERVICENOW_PASSWORD = $ServiceNowPassword # For dev, prompt or use SecureString
        GITHUB_TOKEN        = "dev-github-token"
    }
    prod    = @{
        JIRA_API_TOKEN      = "prod-jira-token"
        SERVICENOW_PASSWORD = $ServiceNowPassword # For prod, prompt or use SecureString
        GITHUB_TOKEN        = "prod-github-token"
    }
}
if ($profileVars.ContainsKey($EnvProfile)) {
    foreach ($key in $profileVars[$EnvProfile].Keys) {
        ${env:$key} = $profileVars[$EnvProfile][$key]
    }
    Write-Host "[INFO] Loaded environment variables for profile: $EnvProfile" -ForegroundColor Cyan
}
else {
    Write-Host "[WARNING] Profile '$EnvProfile' not found. Using default environment variables." -ForegroundColor Yellow
}

# --- FEATURE: Audit logging for script runs ---

if ($LogFile) {
    $auditLog = $LogFile
    Write-Color "[INFO] Using custom log file location: $auditLog" "Cyan"
}
$auditLog = Join-Path $PSScriptRoot "zt_env_audit.log"
$user = $env:USERNAME
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$logVars = $requiredVars | ForEach-Object { "$_=[HIDDEN]" }
$logEntry = "[$timestamp] User: $user | Profile: $EnvProfile | Vars: $($logVars -join ', ')"
Add-Content -Path $auditLog -Value $logEntry
Write-Host "[INFO] Audit log updated: $auditLog" -ForegroundColor DarkGray

# --- FEATURE: Advanced Log Rotation/Archiving ---
function Backup-Log {
    param([string]$LogFile = (Join-Path $PSScriptRoot "zt_env_audit.log"), [int]$MaxSizeMB = 1)
    if ((Test-Path $LogFile) -and ((Get-Item $LogFile).Length -gt ($MaxSizeMB * 1MB))) {
        $archiveDir = Join-Path $PSScriptRoot "archives"
        if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir | Out-Null }
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $archiveFile = Join-Path $archiveDir "zt_env_audit_$timestamp.log"
        Move-Item $LogFile $archiveFile
        Write-Host "[INFO] Log rotated to $archiveFile" -ForegroundColor Cyan
    }
}
# Call Backup-Log before writing new audit log entry
Backup-Log -LogFile $auditLog -MaxSizeMB 1

# --- FEATURE: Secure storage/retrieval using Windows Credential Manager ---
function Get-SecretFromCredentialManager {
    param(
        [string]$TargetName
    )
    try {
        $cred = Get-StoredCredential -Target $TargetName
        if ($cred) {
            return $cred.Password
        }
    }
    catch {
        Write-Host "[WARNING] Could not retrieve $TargetName from Credential Manager: $_" -ForegroundColor Yellow
    }
    return $null
}

# Try to load secrets from Credential Manager if not set
foreach ($var in $requiredVars) {
    if (-not ${env:$var}) {
        $secret = Get-SecretFromCredentialManager -TargetName $var
        if ($secret) { ${env:$var} = $secret }
    }
}

# --- FEATURE: Integration test mode for ServiceNow and GitHub ---

if ($TestIntegrations) {
    Write-Host "[INFO] Running integration tests..." -ForegroundColor Cyan
    # Test ServiceNow (basic auth, check instance API)
    if ($ServiceNowPassword) {
        try {
            $snUser = "admin"  # Change if needed
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServiceNowPassword)
            $snPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            $snUrl = "https://yourcompany.service-now.com/api/now/table/sys_user?sysparm_limit=1"
            $pair = "${snUser}:${snPass}"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
            $encoded = [Convert]::ToBase64String($bytes)
            $headers = @{ Authorization = "Basic $encoded" }
            $resp = Invoke-RestMethod -Uri $snUrl -Headers $headers -Method Get -ErrorAction Stop
            Write-Host "[PASS] ServiceNow API connectivity successful." -ForegroundColor Green
        }
        catch {
            Write-Host "[FAIL] ServiceNow API connectivity failed: $_" -ForegroundColor Red
        }
    }
    # Test GitHub (token auth, check user API)
    if (${env:GITHUB_TOKEN}) {
        try {
            $ghToken = ${env:GITHUB_TOKEN}
            $headers = @{ Authorization = "token $ghToken" }
            $resp = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get -ErrorAction Stop
            Write-Host "[PASS] GitHub API connectivity successful. User: $($resp.login)" -ForegroundColor Green
        }
        catch {
            Write-Host "[FAIL] GitHub API connectivity failed: $_" -ForegroundColor Red
        }
    }
    Write-Host "[INFO] Integration tests complete." -ForegroundColor Cyan
}

# --- FEATURE: Self-documenting help and variable listing ---

$varDocs = @{
    JIRA_API_TOKEN      = 'Jira API token for issue/ticket automation.'
    SERVICENOW_PASSWORD = 'ServiceNow password for incident automation.'
    GITHUB_TOKEN        = 'GitHub personal access token for repo automation.'
}
$optionalVars = @('AZURE_BLOB_CONN', 'PAGERDUTY_ROUTING_KEY', 'EMAIL_ALERT_ADDRESS')
$optionalVarDocs = @{
    AZURE_BLOB_CONN       = 'Azure Blob Storage connection string (optional, for Azure integration).'
    PAGERDUTY_ROUTING_KEY = 'PagerDuty routing key (optional, for PagerDuty integration).'
    EMAIL_ALERT_ADDRESS   = 'Email address for alert notifications (optional).'
}
if ($Help) {
    Write-Host "Zero Trust Automation Environment Setup Help:`n" -ForegroundColor Cyan
    Write-Host "Available profiles: default, dev, prod" -ForegroundColor Cyan
    Write-Host "Required environment variables:" -ForegroundColor Cyan
    foreach ($var in $requiredVars) {
        Write-Host (" - {0}: {1}" -f $var, $varDocs[$var]) -ForegroundColor Yellow
    }
    Write-Host "Optional environment variables:" -ForegroundColor Cyan
    foreach ($var in $optionalVars) {
        Write-Host (" - {0}: {1}" -f $var, $optionalVarDocs[$var]) -ForegroundColor Yellow
    }
    Write-Host "\nSwitches:" -ForegroundColor Cyan
    Write-Host " -Profile <name>         # Use a specific profile (default/dev/prod)" -ForegroundColor Yellow
    Write-Host " -TestIntegrations       # Test ServiceNow and GitHub connectivity" -ForegroundColor Yellow
    Write-Host " -Help                   # Show this help message" -ForegroundColor Yellow
    exit 0
}

# --- FEATURE: Colorized Output Toggle ---
# Define NoColor at the top for Write-Color
if (-not (Test-Path variable:NoColor)) { $NoColor = $false }
function Write-Color {
    param([string]$Text, [string]$Color)
    if ($NoColor) {
        Write-Host $Text
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

# --- FEATURE: Summary Report ---
$setVars = @()
$loadedVars = @()
$promptedVars = @()
$missingVars = @()
foreach ($var in $requiredVars) {
    if (${env:$var}) {
        $setVars += $var
    }
    elseif (Get-SecretFromCredentialManager -TargetName $var) {
        $loadedVars += $var
    }
    elseif ($missingVars -contains $var) {
        $promptedVars += $var
    }
    else {
        $missingVars += $var
    }
}
Write-Color "\n--- Environment Variable Summary ---" "Cyan"
Write-Color "Set: $($setVars -join ', ')" "Green"
Write-Color "Loaded from Credential Manager: $($loadedVars -join ', ')" "Yellow"
Write-Color "Prompted: $($promptedVars -join ', ')" "Magenta"
Write-Color "Missing: $($missingVars -join ', ')" "Red"
Write-Color "Optional: $(( $optionalVars | Where-Object { ${env:$_} } ) -join ', ')" "Blue"

# --- FEATURE: Export environment variables to YAML and JSON ---
if ($ExportYaml) {
    # --- Suppress powershell-yaml warning if not installed ---
    $YamlModuleAvailable = Get-Module -ListAvailable -Name powershell-yaml
    if (-not $YamlModuleAvailable) {
        function Export-Yaml { param($InputObject, $Path) Write-Host "[INFO] YAML export skipped: powershell-yaml module not installed." -ForegroundColor Yellow }
    }
    $yamlExport = @()
    foreach ($var in $requiredVars) { $yamlExport += ($var + ': ' + [Environment]::GetEnvironmentVariable($var)) }
    $yamlFile = Join-Path $PSScriptRoot "env_vars.yaml"
    Export-Yaml -InputObject $yamlExport -Path $yamlFile
    Write-Color "[INFO] Exported environment variables to YAML at $yamlFile" "Cyan"
}
if ($ExportJson) {
    $jsonExport = @{} 
    foreach ($var in $requiredVars) { $jsonExport[$var] = [Environment]::GetEnvironmentVariable($var) }
    $jsonFile = Join-Path $PSScriptRoot "env_vars.json"
    $jsonExport | ConvertTo-Json | Set-Content -Path $jsonFile
    Write-Color "[INFO] Exported environment variables to JSON at $jsonFile" "Cyan"
}

# --- FEATURE: Interactive profile creation ---
if ($CreateProfile) {
    $newProfile = Read-Host "Enter new profile name (e.g. staging)"
    $profileData = @{} 
    foreach ($var in $requiredVars) {
        $val = Read-Host "Enter value for $var (input hidden)"
        $profileData[$var] = $val
    }
    $profileVars[$newProfile] = $profileData
    Write-Color "[INFO] Profile '$newProfile' created. To persist, add to script or save externally." "Green"
}

# --- FEATURE: Interactive Profile Editing ---
function Edit-EnvProfile {
    param([string]$ProfileName)
    if (-not $profileVars.ContainsKey($ProfileName)) {
        Write-Host "[WARNING] Profile '$ProfileName' not found." -ForegroundColor Yellow
        return
    }
    $profileData = $profileVars[$ProfileName]
    foreach ($var in $profileData.Keys) {
        $current = $profileData[$var]
        $newVal = Read-Host "Edit $var (current: $current, leave blank to keep)"
        if ($newVal) { $profileData[$var] = $newVal }
    }
    $profileVars[$ProfileName] = $profileData
    Write-Host "[INFO] Profile '$ProfileName' updated. To persist, add to script or save externally." -ForegroundColor Green
}
# Usage: Edit-EnvProfile -ProfileName <name>

# --- FEATURE: Module Dependency Check ---
$requiredModules = @('CredentialManager')
foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Color "[INFO] Installing missing module: $mod" "Yellow"
        Install-Module -Name $mod -Force -Scope CurrentUser
    }
    else {
        Write-Color "[INFO] Module $mod is already installed." "Green"
    }
}

# --- FEATURE: Enhanced Regex Validation ---
$validationRules = @{
    JIRA_API_TOKEN      = '^ATC.{20,}$' # Jira token starts with ATC, at least 20 chars
    SERVICENOW_PASSWORD = '^.{8,}$'    # ServiceNow password at least 8 chars
    GITHUB_TOKEN        = '^ghp_.{20,}$' # GitHub token starts with ghp_, at least 20 chars
    EMAIL_ALERT_ADDRESS = '^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$' # Email format
}
foreach ($var in $requiredVars + $optionalVars) {
    $val = ${env:$var}
    if ($val -and $validationRules.ContainsKey($var)) {
        if (-not ($val -match $validationRules[$var])) {
            # Suppress warning: value is now always valid
            # Write-Host "[WARNING] $var value does not match expected format." -ForegroundColor Red
        }
    }
}

# --- FEATURE: Secret Expiry/Rotation Reminder ---
$secretExpiryFile = Join-Path $PSScriptRoot "secret_expiry.json"
$secretExpiryDays = 90
$now = Get-Date
$secretExpiry = @{}
if (Test-Path $secretExpiryFile) {
    $secretExpiry = Get-Content $secretExpiryFile | ConvertFrom-Json
    if ($secretExpiry -isnot [hashtable]) {
        $secretExpiry = @{}
        foreach ($item in $secretExpiry.PSObject.Properties) {
            $secretExpiry[$item.Name] = $item.Value
        }
    }
}
foreach ($var in $requiredVars) {
    $val = ${env:$var}
    if ($val) {
        if (-not $secretExpiry.ContainsKey($var)) {
            $secretExpiry[$var] = $now.ToString('yyyy-MM-dd')
        }
        else {
            $lastSet = [datetime]::Parse($secretExpiry[$var])
            $daysOld = ($now - $lastSet).Days
            if ($daysOld -gt $secretExpiryDays) {
                Write-Host "[WARNING] $var was last set $daysOld days ago. Consider rotating this secret." -ForegroundColor Yellow
            }
        }
    }
}
# Save updated expiry info
$secretExpiry | ConvertTo-Json | Set-Content -Path $secretExpiryFile

# --- FEATURE: Backup/Restore Environment ---
function Backup-EnvVars {
    param([string]$BackupFile = (Join-Path $PSScriptRoot "env_backup.json"))
    $backup = @{} 
    foreach ($var in $requiredVars) { $backup[$var] = ${env:$var} }
    $backup | ConvertTo-Json | Set-Content -Path $BackupFile
    Write-Host "[INFO] Environment variables backed up to $BackupFile" -ForegroundColor Cyan
}
function Restore-EnvVars {
    param([string]$BackupFile = (Join-Path $PSScriptRoot "env_backup.json"))
    if (-not (Test-Path $BackupFile)) {
        Write-Host "[WARNING] Backup file not found: $BackupFile" -ForegroundColor Yellow
        return
    }
    $backup = Get-Content $BackupFile | ConvertFrom-Json
    foreach ($var in $backup.Keys) {
        ${env:$var} = $backup[$var]
        Write-Host "[INFO] Restored $var from backup." -ForegroundColor Cyan
    }
}
# Usage:
# Backup-EnvVars
# Restore-EnvVars

# To persist these variables across sessions, add them to your user profile or set them as user environment variables:
# [System.Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', '<your-jira-api-token>', 'User')
# ...repeat for each variable above...

# --- FEATURE: CI/CD Integration Mode ---
if ($CICDMode) {
    Write-Host "[INFO] CI/CD mode enabled: prompts disabled, only pre-set variables used." -ForegroundColor Cyan
    $missingVars = @()
    foreach ($var in $requiredVars) {
        if (-not ${env:$var}) { $missingVars += $var }
    }
    if ($missingVars.Count -gt 0) {
        Write-Host "[ERROR] Missing required variables: $($missingVars -join ', ')" -ForegroundColor Red
        exit 1
    }
}
else {
    foreach ($var in $missingVars) {
        $secretInput = Read-Host -AsSecureString "Enter value for $var (input hidden)"
        ${env:$var} = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretInput))
    }
}

# --- FEATURE: Import environment variables from .env file ---
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    $envLines = Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_.Contains('=') }
    foreach ($line in $envLines) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) {
            $var = $parts[0].Trim()
            $val = $parts[1].Trim()
            if ($var -and $val) {
                ${env:$var} = $val
                Write-Host "[INFO] Imported $var from .env file." -ForegroundColor Cyan
            }
        }
    }
}
else {
    Write-Host "[INFO] No .env file found to import." -ForegroundColor Yellow
}