# PowerShell script to launch all SOC microservices in background terminals
$services = @(
    'threat_intel/threat_intel.py',
    'attack_graph/attack_graph.py',
    'autonomous_defense/autonomous_defense.py',
    'dark_web_hunting/dark_web_hunting.py',
    'threat_actor_attribution/threat_actor_attribution.py',
    'threat_hunting_ai/threat_hunting_ai.py'
)

foreach ($svc in $services) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& 'C:\Users\user\OneDrive\zero-trust-architecture-main-all\venv\Scripts\Activate.ps1'; python soc_dashboard\backend\$svc"
}

Write-Host 'All SOC microservices are launching in new PowerShell windows.'
