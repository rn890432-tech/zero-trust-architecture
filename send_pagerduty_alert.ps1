param(
    [Parameter(Mandatory = $false)]
    [SecureString]$RoutingKey,
    [Parameter(Mandatory = $true)]
    [string]$Summary,
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $false)]
    [string]$Severity = "critical"
)

# Prompt for RoutingKey as SecureString if not provided
if (-not $RoutingKey) {
    $RoutingKey = Read-Host -AsSecureString "Enter PagerDuty Routing Key (input hidden)"
}
# Convert SecureString to plain text for HTTP body
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($RoutingKey)
$plainRoutingKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$body = @{
    routing_key = $plainRoutingKey
    event_action = "trigger"
    payload = @{
        summary = $Summary
        source = $Source
        severity = $Severity
    }
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://events.pagerduty.com/v2/enqueue" -Method Post -ContentType 'application/json' -Body $body
Write-Host "PagerDuty event sent. Response: $($response.status)"
