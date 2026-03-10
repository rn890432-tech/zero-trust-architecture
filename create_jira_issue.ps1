param(
    [Parameter(Mandatory = $true)]
    [string]$Summary,
    [Parameter(Mandatory = $true)]
    [string]$Description,
    [Parameter(Mandatory = $true)]
    [string]$JiraUrl,
    [Parameter(Mandatory = $true)]
    [string]$ProjectKey,
    [Parameter(Mandatory = $true)]
    [string]$IssueType,
    [Parameter(Mandatory = $true)]
    [string]$Username,
    [Parameter(Mandatory = $false)]
    [SecureString]$ApiToken
)

# Prompt for Jira API token as SecureString if not provided
if (-not $ApiToken) {
    $ApiToken = Read-Host -AsSecureString "Enter Jira API token (input hidden)"
}
# Convert SecureString to plain text for HTTP header
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiToken)
$plainApiToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username:$plainApiToken"))
$body = @{
    fields = @{
        project     = @{ key = $ProjectKey }
        summary     = $Summary
        description = $Description
        issuetype   = @{ name = $IssueType }
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "$JiraUrl/rest/api/2/issue" -Method Post -Headers @{Authorization = "Basic $base64AuthInfo"; 'Content-Type' = 'application/json'} -Body $body
Write-Host "Jira issue created: $($response.key)"
