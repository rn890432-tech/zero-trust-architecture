# Defense-in-Depth Summary: Cloud & Identity Security Posture (Q1 2026)

| Pillar        | Focus Area      | Key Control Implemented                | Audit Artifact                |
|---------------|----------------|----------------------------------------|-------------------------------|
| **Identity**   | Access Entry    | Phishing-Resistant MFA & OAuth Governance | IAM_01_MFA_Policy.pdf         |
| **Entitlements** | Blast Radius  | Just-In-Time (JIT) Admin Access (PIM)  | ENT_01_PIM_Logs.csv           |
| **Data**       | Exposure        | Global “Block Public Access” (BPA)     | DATA_01_BPA_Config.png        |

---

**Strategic Narrative:**
- **Identity:** We recognize AiTM phishing risks. We’ve moved beyond passwords to managed OAuth consent and automated session revocation to kill stolen tokens.
- **Entitlements:** No standing access. Admins elevate only with ticket approval, minimizing blast radius.
- **Data:** Platform-level protection—new storage is private by default, preventing accidental exposure.

**Compliance Maturity:**
- Control Coverage: 100% of defined Identity and Data controls
- Testing Frequency: Monthly automation + annual external audit
- Remediation Status: 0 critical/high findings; low findings tracked in POA&M

**Pro-Tip Response:**
If asked about JIT admin compromise:
> Our SOC is alerted on every PIM elevation. If paired with an anomalous login, we trigger ‘Global Token Revocation’ via our Kill-Switch SOP.
