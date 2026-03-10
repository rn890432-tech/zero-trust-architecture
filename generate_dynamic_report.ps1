param(
    [Parameter(Mandatory = $true)]
    [string]$ReportPath,
    [Parameter(Mandatory = $true)]
    [string]$Date,
    [Parameter(Mandatory = $true)]
    [string]$Summary,
    [Parameter(Mandatory = $true)]
    [array]$Details
)

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Security Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 2em; }
        h1 { color: #2c3e50; }
        table { border-collapse: collapse; width: 100%; margin-top: 1em; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background: #f4f4f4; }
        .summary { margin-bottom: 1em; }
    </style>
</head>
<body>
    <h1>Security Audit Report</h1>
    <p>Date: <span id="report-date">$Date</span></p>
    <div class="summary">
        <h2>Summary</h2>
        <p id="summary-text">$Summary</p>
    </div>
    <h2>Details</h2>
    <table>
        <tr>
            <th>Check</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
"@

foreach ($row in $Details) {
    $html += "        <tr>"
    $html += "<td>$($row.Check)</td>"
    $html += "<td>$($row.Status)</td>"
    $html += "<td>$($row.Details)</td>"
    $html += "</tr>"
}

$html += @"
    </table>
    <p>For more details, see the attached logs or contact the security team.</p>
</body>
</html>
"@

Set-Content -Path $ReportPath -Value $html
Write-Host "Report generated at $ReportPath"
