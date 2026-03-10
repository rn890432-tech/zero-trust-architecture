param(
    [Parameter(Mandatory = $true)]
    [string]$ShortDescription,
    [Parameter(Mandatory = $true)]
    [string]$Description,
    [Parameter(Mandatory = $true)]
    [string]$ServiceNowUrl,
    [Parameter(Mandatory = $true)]
    [string]$Username,
    [Parameter(Mandatory = $true)]
    [SecureString]$Password
)

# Prepare request body
$body = @{
    short_description = $ShortDescription
    description = $Description
} | ConvertTo-Json

# Convert SecureString to plain text for API call
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
)
$pair = "${Username}:$plainPassword"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)
$headers = @{
    Authorization = "Basic $base64"
    'Content-Type' = 'application/json'
}

# Make the API call with error handling
try {
    $response = Invoke-RestMethod -Uri ("$ServiceNowUrl/api/now/table/incident") -Method Post -Headers $headers -Body $body -ErrorAction Stop
    if ($response.result.number) {
        Write-Host "ServiceNow incident created: $($response.result.number)"
    } else {
        Write-Warning "ServiceNow incident creation response did not contain an incident number. Full response: $($response | ConvertTo-Json -Depth 5)"
    }
} catch {
    Write-Error "Failed to create ServiceNow incident: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Error "Details: $($_.ErrorDetails.Message)"
    }
    exit 1
}
