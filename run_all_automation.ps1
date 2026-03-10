# This script automates the environment setup and runs your automation script
# Usage: pwsh -File run_all_automation.ps1

# Set environment variables for Zero Trust Automation
. "$PSScriptRoot\set_zt_env_vars.ps1"

# Run your automation script
. "$PSScriptRoot\automate_report_and_email.ps1"
