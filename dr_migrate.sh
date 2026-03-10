#!/bin/bash
# Disaster Recovery (DR) Script for SOC Command Center
# Usage: ./dr_migrate.sh <secondary_server_ip>

SECONDARY_IP="$1"

# 1. Sync audit log and config to secondary
rsync -avz phishing_events.log config.yml $SECONDARY_IP:/opt/soc/

# 2. Activate virtual environment on secondary
ssh $SECONDARY_IP "cd /opt/soc && source venv/bin/activate"

# 3. Update REDIS_URL in app.py to failover instance
ssh $SECONDARY_IP "sed -i 's/REDIS_URL=.*/REDIS_URL="redis://failover:6379"/' app.py"

# 4. DNS switch
# (Assumes you have access to DNS management)
echo "Switching DNS for soc.company.com to $SECONDARY_IP"
# Example: nsupdate or API call (manual step if not automated)

# 5. Verify migration
ssh $SECONDARY_IP "python test_soc_pipeline.py"

# 6. Confirm audit log integrity
ssh $SECONDARY_IP "ls -l phishing_events.log && tail -n 10 phishing_events.log"

# 7. Generate Audit PDF
ssh $SECONDARY_IP "python app.py --export-audit-pdf"

echo "DR migration complete. Verify dashboard and alerts on secondary site."
