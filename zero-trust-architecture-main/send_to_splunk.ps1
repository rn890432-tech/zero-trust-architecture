# For each new incident or critical event
foreach ($incident in $newCriticals) {
    $eventJson = @{
        time = (Get-Date -UFormat %s)
        host = $env:COMPUTERNAME
        source = "ZeroTrustAutomation"
        event = @{
            type = "incident"
            severity = "critical"
            details = $incident
        }
    } | ConvertTo-Json -Compress

    & "$PSScriptRoot\send_to_splunk.ps1" -SplunkHECUrl $env:SPLUNK_HEC_URL -HECToken (ConvertTo-SecureString $env:SPLUNK_HEC_TOKEN -AsPlainText -Force) -EventJson $eventJson
}param(
    [Parameter(Mandatory = $true)]
    [string]$SplunkHECUrl,
    [Parameter(Mandatory = $false)]
    [SecureString]$HECToken,
    [Parameter(Mandatory = $true)]
    [string]$EventJson
)

# Prompt for HEC token as SecureString if not provided
if (-not $HECToken) {
    $HECToken = Read-Host -AsSecureString "Enter Splunk HEC Token (input hidden)"
}
# Convert SecureString to plain text for HTTP header
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($HECToken)
$plainHECToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$headers = @{ 'Authorization' = "Splunk $plainHECToken"; 'Content-Type' = 'application/json' }
$body = @{ event = $EventJson } | ConvertTo-Json
$response = Invoke-RestMethod -Uri $SplunkHECUrl -Method Post -Headers $headers -Body $body
Write-Host "Splunk event sent. Response: $($response.text)"
