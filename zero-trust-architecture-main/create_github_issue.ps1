param(
    [Parameter(Mandatory = $true)]
    [string]$RepoOwner,
    [Parameter(Mandatory = $true)]
    [string]$RepoName,
    [Parameter(Mandatory = $true)]
    [string]$Title,
    [Parameter(Mandatory = $true)]
    [string]$Body,
    [Parameter(Mandatory = $false)]
    [SecureString]$GitHubToken
)

# Prompt for GitHub token as SecureString if not provided
if (-not $GitHubToken) {
    $GitHubToken = Read-Host -AsSecureString "Enter GitHub token (input hidden)"
}
# Convert SecureString to plain text for HTTP header
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken)
$plainGitHubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$headers = @{ Authorization = "token $plainGitHubToken"; 'User-Agent' = 'ZeroTrustBot' }
$issue = @{ title = $Title; body = $Body } | ConvertTo-Json
$url = "https://api.github.com/repos/$RepoOwner/$RepoName/issues"
$response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $issue
Write-Host "GitHub issue created: $($response.html_url)"
