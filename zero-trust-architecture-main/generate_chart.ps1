param(
    [Parameter(Mandatory = $true)]
    [array]$Details,
    [Parameter(Mandatory = $true)]
    [string]$ChartPath
)

# Chart generation using PSWriteHTML and wkhtmltoimage
try {
    if (-not (Get-Module -ListAvailable -Name PSWriteHTML)) {
        Install-Module -Name PSWriteHTML -Force -Scope CurrentUser
    }
    Import-Module PSWriteHTML
    $labels = $Details | ForEach-Object { $_.Check }
    $values = $Details | ForEach-Object { if ($_.Status -match 'pass|up|100' -i) { 1 } else { 0 } }
    $htmlFile = $ChartPath.Replace('.png','.html')
    New-HTML -FilePath $htmlFile -ShowHTML:$false {
        New-HTMLChart -Title 'Audit Status' -Labels $labels -Values $values -Type Bar
    }
    $cmd = "wkhtmltoimage --width 600 --height 400 `"$htmlFile`" `"$ChartPath`""
    Invoke-Expression $cmd
    Remove-Item $htmlFile -Force
    Write-Host "Chart generated at $ChartPath."
} catch {
    Write-Host "WARNING: Chart generation failed: $_"
    Add-Content -Path $ChartPath -Value "" # Placeholder
}
