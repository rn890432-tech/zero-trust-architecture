threat_actors = [
    {
        "name": "Lazarus Group",
        "ips": ["185.22.10.5"],
        "domains": ["lazarus-malware.com"],
        "malware": ["DarkHydra"],
        "techniques": ["lateral_movement", "credential_access"],
        "industries": ["finance", "government"],
        "geo": ["North Korea"]
    },
    {
        "name": "LockBit",
        "ips": ["91.210.14.2"],
        "domains": ["lockbit-leak.com"],
        "malware": ["LockBitRansom"],
        "techniques": ["ransomware", "data_exfiltration"],
        "industries": ["healthcare", "manufacturing"],
        "geo": ["Russia"]
    }
]

def get_actors():
    return threat_actors
