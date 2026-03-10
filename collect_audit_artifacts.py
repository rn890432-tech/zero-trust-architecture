import os
import glob
import csv
from datetime import datetime

# Define required artifacts and their expected filenames/extensions
REQUIRED_ARTIFACTS = [
    ('IAM_01_MFA_Policy.pdf', 'PDF'),
    ('ENT_01_PIM_Logs.csv', 'CSV'),
    ('DATA_01_BPA_Config.png', 'PNG'),
    ('Remediation_Tracker_POAM.csv', 'CSV'),
    ('Evidence_Integrity_Manifest.csv', 'CSV'),
]

AUDIT_DIR = '.'  # Change to your audit folder path if needed

summary = []
for filename, filetype in REQUIRED_ARTIFACTS:
    found = False
    for root, dirs, files in os.walk(AUDIT_DIR):
        if filename in files:
            found = True
            full_path = os.path.join(root, filename)
            summary.append({'Artifact': filename, 'Type': filetype, 'Found': 'Yes', 'Path': full_path})
            break
    if not found:
        summary.append({'Artifact': filename, 'Type': filetype, 'Found': 'No', 'Path': ''})

# Output summary report
report_file = f'audit_artifact_summary_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
with open(report_file, 'w', newline='') as csvfile:
    fieldnames = ['Artifact', 'Type', 'Found', 'Path']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for row in summary:
        writer.writerow(row)

print(f"Audit artifact summary written to {report_file}")
