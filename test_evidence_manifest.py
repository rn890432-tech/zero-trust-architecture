import os
import csv
import pytest

def test_evidence_manifest_exists():
    assert os.path.exists('Evidence_Integrity_Manifest.csv') or os.path.exists('archives/Evidence_Integrity_Manifest.csv')

def test_evidence_manifest_format():
    path = 'Evidence_Integrity_Manifest.csv' if os.path.exists('Evidence_Integrity_Manifest.csv') else 'archives/Evidence_Integrity_Manifest.csv'
    with open(path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        required_fields = {'Algorithm', 'Hash', 'Path'}
        assert required_fields.issubset(reader.fieldnames)

def test_evidence_naming_convention():
    path = 'Evidence_Integrity_Manifest.csv' if os.path.exists('Evidence_Integrity_Manifest.csv') else 'archives/Evidence_Integrity_Manifest.csv'
    with open(path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            filename = os.path.basename(row['Path'])
            assert any(prefix in filename for prefix in ['IAM_01', 'OAUTH_02', 'DET_03', 'MAIL_04', 'IR_05'])
