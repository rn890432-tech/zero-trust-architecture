from fpdf import FPDF
import json

def export_daily_report():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(200, 10, txt="Daily Phishing Incident Audit Report", ln=True, align='C')
    pdf.set_font("Arial", size=10)
    with open("phishing_events.log", "r") as f:
        for line in f:
            entry = json.loads(line)
            report_line = f"{entry['timestamp']} - {entry['brand']} - {entry['url']} - Status: {entry['status']}"
            pdf.cell(200, 10, txt=report_line, ln=True)
    pdf.output("Daily_SOC_Audit.pdf")

# Can be scheduled via Cron job every night at 23:59
