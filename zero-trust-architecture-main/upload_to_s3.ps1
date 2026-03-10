param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string]$Bucket,
    [Parameter(Mandatory = $true)]
    [string]$Key,
    [Parameter(Mandatory = $false)]
    [SecureString]$AWSAccessKey,
    [Parameter(Mandatory = $false)]
    [SecureString]$AWSSecretKey
)

# Convert SecureString to plain text if provided
if ($AWSAccessKey) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWSAccessKey)
    $plainAWSAccessKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    Set-Item -Path Env:AWS_ACCESS_KEY_ID -Value $plainAWSAccessKey
}
if ($AWSSecretKey) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWSSecretKey)
    $plainAWSSecretKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    Set-Item -Path Env:AWS_SECRET_ACCESS_KEY -Value $plainAWSSecretKey
}

try {
    if (-not (Get-Module -ListAvailable -Name AWS.Tools.S3)) {
        Install-Module -Name AWS.Tools.S3 -Force -Scope CurrentUser
    }
    Import-Module AWS.Tools.S3
    Write-S3Object -BucketName $Bucket -File $FilePath -Key $Key -CannedACLName 'public-read'
    $url = "https://$Bucket.s3.amazonaws.com/$Key"
    Write-Host "Uploaded $FilePath to S3: $url"
    return $url
} catch {
    Write-Host "WARNING: S3 upload failed: $_"
    return $null
}
