import os
import csv
import pytest

def test_remediation_tracker_exists():
    assert os.path.exists('Remediation_Tracker_POAM.csv') or os.path.exists('archives/Remediation_Tracker_POAM.csv')

def test_remediation_tracker_format():
    path = 'Remediation_Tracker_POAM.csv' if os.path.exists('Remediation_Tracker_POAM.csv') else 'archives/Remediation_Tracker_POAM.csv'
    with open(path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        required_fields = {'Gap', 'Status', 'Mitigation', 'LastUpdated'}
        assert required_fields.issubset(reader.fieldnames)

def test_legacy_oauth_gap_tracked():
    path = 'Remediation_Tracker_POAM.csv' if os.path.exists('Remediation_Tracker_POAM.csv') else 'archives/Remediation_Tracker_POAM.csv'
    with open(path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        found = any('legacy OAuth' in row['Gap'].lower() for row in reader)
        assert found
