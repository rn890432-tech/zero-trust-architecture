param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $false)]
    [SecureString]$ConnectionString,
    [Parameter(Mandatory = $true)]
    [string]$Container
)

# Prompt for ConnectionString as SecureString if not provided
if (-not $ConnectionString) {
    $ConnectionString = Read-Host -AsSecureString "Enter Azure Blob Connection String (input hidden)"
}
# Convert SecureString to plain text for context
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ConnectionString)
$plainConnectionString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

try {
    if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
        Import-Module Az.Storage -ErrorAction Stop
    }
    $ctx = New-AzStorageContext -ConnectionString $plainConnectionString
    $blob = Set-AzStorageBlobContent -File $FilePath -Container $Container -Context $ctx -Force
    $url = $blob.ICloudBlob.Uri.AbsoluteUri
    Write-Host "Uploaded $FilePath to Azure Blob: $url"
    return $url
} catch {
    Write-Host "WARNING: Azure Blob upload failed: $_"
    return $null
}
