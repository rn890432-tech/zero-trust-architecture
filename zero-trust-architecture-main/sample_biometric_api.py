@app.route('/api/export_pdf', methods=['POST'])
def export_pdf():
    data = request.json
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", 'B', 14)
    pdf.cell(200, 10, txt="Phishing Incident Report", ln=True, align='C')
    pdf.set_font("Arial", size=10)
    pdf.multi_cell(0, 8, txt=data.get('report_text', 'No report text provided'))
    filename = f"phishing_incident_{data.get('url','report')}.pdf"
    pdf.output(filename)
    return jsonify({"pdf_file": filename})

@app.route('/api/send_report_email', methods=['POST'])
def send_report_email():
    data = request.json
    recipient = data.get('recipient', 'soc@example.com')
    subject = "Phishing Incident Report"
    body = data.get('report_text', '')
    # Simulate sending email
    return jsonify({"status": "Email sent to " + recipient, "subject": subject, "body": body})

@app.route('/api/threat_feed', methods=['GET'])
def threat_feed():
    feed = [
        {"threat": "New phishing campaign targeting Microsoft users", "date": "2026-03-05"},
        {"threat": "Zero-day exploit in Adobe Sign", "date": "2026-03-04"},
        {"threat": "DocuSign spoofing detected in multiple regions", "date": "2026-03-03"}
    ]
    return jsonify({"feed": feed})

@app.route('/api/analytics', methods=['GET'])
def analytics():
    summary = {
        "total_incidents": 42,
        "high_risk": 17,
        "low_risk": 25,
        "most_targeted_brand": "Microsoft",
        "last_incident": "2026-03-05"
    }
    return jsonify(summary)
@app.route('/api/generate_report', methods=['POST'])
def generate_report():
    data = request.json
    report_content = f'PHISHING INCIDENT REPORT\n' \
                     f'URL: {data.get("url")}\n' \
                     f'Risk: {data.get("risk_level")}\n' \
                     f'Findings: {", ".join(data.get("findings", []))}\n' \
                     f'Red-Team Framework: Applied\n' \
                     f'Golden Rule: Never enter credentials on a login page embedded in another window.\n' \
                     f'Vigilance Status: Active'
    return jsonify({"report_text": report_content})
@app.route('/api/generate_report', methods=['POST'])
def generate_report():
    data = request.json
    report_content = f"PHISHING INCIDENT REPORT\n" \
                     f"URL: {data.get('url')}\n" \
                     f"Risk: {data.get('risk_level')}\n" \
                     f"Findings: {', '.join(data.get('findings', []))}\n" \
                     f"Step-by-Step Red-Team Analysis: {chr(10).join(data.get('red_team_steps', []))}\n" \
                     f"Golden Rule: Never enter credentials on a login page embedded in another window.\n" \
                     f"Vigilance Status: Active"
    return jsonify({"report_text": report_content})
from fpdf import FPDF
def export_phishing_incident_report(url, analysis, format='pdf'):
    summary = f"Phishing Incident Report\nURL: {url}\nRisk Level: {analysis['risk_level']}\nRecommendation: {analysis['recommendation']}\n\nFindings:\n"
    for finding in analysis['findings']:
        summary += f"- {finding}\n"
    summary += "\nRed-Team Analysis Steps:\n"
    for step in analysis['red_team_steps']:
        summary += f"- {step}\n"
    if format == 'pdf':
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", 'B', 14)
        pdf.cell(200, 10, txt="Phishing Incident Report", ln=True, align='C')
        pdf.set_font("Arial", size=10)
        for line in summary.split('\n'):
            pdf.cell(200, 8, txt=line, ln=True)
        filename = f"phishing_incident_{url.replace('://','_').replace('/','_')}.pdf"
        pdf.output(filename)
        return filename
    else:
        filename = f"phishing_incident_{url.replace('://','_').replace('/','_')}.txt"
        with open(filename, 'w') as f:
            f.write(summary)
        return filename
import re
from urllib.parse import urlparse
from flask import Flask, request, jsonify
import random

app = Flask(__name__)

def analyze_phishing_risk(url):
    """
    Red-Team Style Analysis Framework
    Step 1: Examine URL Format & Domain Legitimacy
    """
    suspicious_indicators = []
    red_team_steps = []
    parsed = urlparse(url)
    domain = parsed.netloc.lower()
    legit_domains = ['login.microsoftonline.com', 'adobesign.com', 'echosign.com', 'docusign.com']
    # Step 1: Domain legitimacy
    if domain and domain not in legit_domains:
        if any(brand in domain for brand in ['microsoft', 'adobe', 'docusign']):
            suspicious_indicators.append("Potential Homoglyph or Misspelling detected")
            red_team_steps.append("Step 1: Domain legitimacy failed (homoglyph/misspelling)")
        else:
            red_team_steps.append("Step 1: Domain legitimacy failed (not official)")
    else:
        red_team_steps.append("Step 1: Domain legitimacy passed")
    # Step 2: Subdomain analysis
    if len(domain.split('.')) > 3:
        suspicious_indicators.append("Multi-layered subdomain detected; often used in proxy phish")
        red_team_steps.append("Step 2: Multi-layered subdomain flagged")
    else:
        red_team_steps.append("Step 2: Subdomain structure normal")
    # Step 3: Behavioral Flow: Check for immediate credential requests
    if 'password' in url or 'signin' in url:
        suspicious_indicators.append("Suspicious ask: requesting password before document")
        red_team_steps.append("Step 3: Suspicious ask flagged")
    else:
        red_team_steps.append("Step 3: No suspicious ask detected")
    # Step 4: Embedded login window detection (simulated)
    if 'embed' in url or 'window' in url:
        suspicious_indicators.append("Possible embedded login window")
        red_team_steps.append("Step 4: Embedded login window flagged")
    else:
        red_team_steps.append("Step 4: No embedded login window detected")
    # Step 5: Layout/branding check (simulated)
    if 'logo' not in url or 'footer' not in url:
        suspicious_indicators.append("Low-quality branding or missing legal footer")
        red_team_steps.append("Step 5: Branding/layout issue flagged")
    else:
        red_team_steps.append("Step 5: Branding/layout appears normal")
    # Step 6: OAuth consent screen (simulated)
    if 'oauth' in url or 'consent' in url:
        suspicious_indicators.append("OAuth consent screen detected; verify app identity")
        red_team_steps.append("Step 6: OAuth consent screen flagged")
    else:
        red_team_steps.append("Step 6: No OAuth consent screen detected")
    # AI creative suggestion integration
    ai_suggestions = [
        "Simulate a targeted phishing campaign using homoglyph domains.",
        "Analyze user click patterns for suspicious login prompts.",
        "Detect multi-layered subdomain attacks in real time.",
        "Create a scenario for credential harvesting via OAuth consent screens.",
        "Monitor for unusual MFA requests from non-standard domains."
    ]
    # User-driven scenario (simulated)
    scenario = None
    # Finalize risk
    risk_score = "HIGH" if suspicious_indicators else "LOW"
    recommendation = "STOP. Report to security team if risk is HIGH." if risk_score == "HIGH" else "No immediate risk detected."
    training_material = {
        'Microsoft': [
            'Never enter credentials on a Microsoft login page embedded in another window.',
            'Only trust login.microsoftonline.com.',
            'Look for official logos and legal footers.'
        ],
        'Adobe': [
            'Adobe sign-in should only occur on adobe.com domains.',
            'Watch for misspelled or extra subdomains.',
            'Official branding and security notices must be present.'
        ],
        'DocuSign': [
            'DocuSign login should only be on docusign.com.',
            'Beware of nested subdomains or unrelated root domains.',
            'Look for DocuSign security banners and legal footers.'
        ]
    }
    return {
        "url": url,
        "risk_level": risk_score,
        "findings": suspicious_indicators + [f"AI Suggestion: {random.choice(ai_suggestions)}"],
        "recommendation": recommendation,
        "red_team_steps": red_team_steps,
        "training_material": training_material
    }
@app.route('/api/analyze', methods=['POST'])
def security_analysis():
    data = request.json or {}
    url = data.get('url', '')
    scenario = data.get('scenario', None)
    analysis = analyze_phishing_risk(url)
    result = {
        'url': analysis['url'],
        'risk_level': analysis['risk_level'],
        'findings': analysis['findings'],
        'recommendation': analysis['recommendation'],
        'red_team_steps': analysis['red_team_steps'],
        'training_material': analysis['training_material']
    }
    # Export report if high risk
    if analysis['risk_level'] == 'HIGH':
        report_format = data.get('report_format', 'pdf')
        report_file = export_phishing_incident_report(url, analysis, format=report_format)
        result['incident_report_file'] = report_file
    return jsonify(result)
@app.route('/api/url-inspector', methods=['POST'])
def url_inspector():
    data = request.json or {}
    url = data.get('url', '')
    # Simulated Red-Team Analysis Framework steps
    steps = [
        f"Step 1: Check domain → {url.split('/')[2] if '://' in url else url}",
        "Step 2: Inspect for typosquatting or suspicious subdomains.",
        "Step 3: Verify HTTPS and certificate validity.",
        "Step 4: Click padlock and review certificate issuer and expiration.",
        "Step 5: Look for OAuth consent screens and verify app identity.",
        "Step 6: Check for urgent language, threats, or requests for credentials."
    ]
    return jsonify({"steps": steps})
import random

@app.route('/api/dreamscape', methods=['POST'])
def dreamscape():
    data = request.json or {}
    scenario = data.get('scenario', '')
    # Simulate AI-generated creative suggestions
    base_suggestions = [
        "Visualize notifications as floating clouds to reveal escalation paths.",
        "Transform workflows into labyrinths to expose inefficiencies.",
        "Let dashboards speak in metaphors, guiding creative fixes.",
        "Send notifications before issues occur for dream-logic foresight.",
        "Reflect workflows in mirror worlds to inspire new strategies."
    ]
    # Add user scenario as a seed for creativity
    suggestions = [f"For your scenario '{scenario}', consider: {random.choice(base_suggestions)}"]
    suggestions += random.sample(base_suggestions, k=2)
    return jsonify({"suggestions": suggestions})

import time
import random
import requests
import cv2
from flask import Flask, jsonify, request
from fer import FER

app = Flask(__name__)

# Simulated device APIs (replace with real API calls)
def get_wearable_data():
    # Example: Replace with Fitbit/Apple Watch API call
    # response = requests.get('https://api.fitbit.com/1/user/-/activities/heart.json', headers={...})
    # return response.json()
    return {
        "heart_rate": 85,
        "stress": "moderate",
        "sleep_hours": 6.5
    }

def get_windowshello_status():
    # Example: Replace with local API/file read from C#/UWP bridge
    return {
        "authenticated": True,
        "presence": "detected"
    }

def get_environment_data():
    # Example: Replace with real sensor API
    return {
        "ambient_light": 320,
        "noise_level": 45
    }

def aggregate_biometric_profile():
    webcam_data, _ = analyze_webcam_emotion()
    wearable = get_wearable_data()
    hello = get_windowshello_status()
    activity = get_activity()
    environment = get_environment_data()
    # Sample rule-based aggregation
    stress = "high" if (
        (webcam_data and webcam_data["stressLevel"] == "high") or
        (wearable["heart_rate"] > 90) or
        (activity["fatigueLevel"] == "high")
    ) else "low"
    fatigue = "high" if (
        wearable["sleep_hours"] < 6 or
        activity["fatigueLevel"] == "high" or
        environment["noise_level"] > 70
    ) else "low"
    focus = "high" if (
        hello["authenticated"] and activity["focusLevel"] == "high" and environment["ambient_light"] > 300
    ) else "moderate"
    return {
        "stress": stress,
        "fatigue": fatigue,
        "focus": focus,
        "webcam": webcam_data,
        "wearable": wearable,
        "windowshello": hello,
        "activity": activity,
        "environment": environment
    }

# Consensus algorithm for recommendations (weighted average)
def consensus_decision(recommendations):
    # recommendations: list of dicts with 'recommendation' and 'weight'
    rec_weights = {}
    total_weight = 0
    for rec in recommendations:
        r = rec.get('recommendation')
        w = rec.get('weight', 1)
        rec_weights[r] = rec_weights.get(r, 0) + w
        total_weight += w
    consensus = max(rec_weights, key=rec_weights.get) if rec_weights else None
    return {
        "consensus": consensus,
        "details": rec_weights,
        "total_weight": total_weight
    }

@app.route('/api/consensus', methods=['POST'])
def api_consensus():
    # Accepts JSON array of recommendations via chat interface
    recommendations = request.json or []
    result = consensus_decision(recommendations)
    return api_response(result)

@app.route('/api/biometric/wearable')
def biometric_wearable():
    data = get_wearable_data()
    return api_response(data)

@app.route('/api/biometric/windowshello')
def biometric_windowshello():
    data = get_windowshello_status()
    return api_response(data)

@app.route('/api/biometric/environment')
def biometric_environment():
    data = get_environment_data()
    return api_response(data)

@app.route('/api/biometric/profile')
def biometric_profile():
    data = aggregate_biometric_profile()
    return api_response(data)

def api_response(data, status="success"):
    return jsonify({
        "status": status,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "data": data
    })

def analyze_webcam_emotion():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        return None, None
    ret, frame = cap.read()
    cap.release()
    if not ret:
        return None, None
    detector = FER()
    result = detector.top_emotion(frame)
    emotions = detector.detect_emotions(frame)
    emotion, score = result if result else (None, 0)
    stressLevel = "high" if emotion in ["angry", "fear", "sad"] else "low"
    fatigueLevel = "moderate" if emotion == "sad" else "low"
    focusLevel = "low" if emotion in ["angry", "fear", "sad"] else "high"
    return {
        "stressLevel": stressLevel,
        "focusLevel": focusLevel,
        "fatigueLevel": fatigueLevel,
        "emotion": emotion,
        "score": score
    }, emotions

def get_activity():
    # Simulate keyboard/mouse activity (replace with real logic as needed)
    activity = {
        "keyboard": random.randint(0, 100),
        "mouse": random.randint(0, 100)
    }
    fatigueLevel = "high" if activity["keyboard"] < 20 and activity["mouse"] < 20 else "low"
    focusLevel = "high" if activity["keyboard"] > 50 or activity["mouse"] > 50 else "moderate"
    return {
        "keyboard_activity": activity["keyboard"],
        "mouse_activity": activity["mouse"],
        "fatigueLevel": fatigueLevel,
        "focusLevel": focusLevel
    }

@app.route('/api/biometric', methods=['GET', 'POST'])
def biometric():
    if request.method == 'POST':
        # Accept custom biometric data
        data = request.json or {}
        return api_response(data, status="posted")
    data, _ = analyze_webcam_emotion()
    if not data:
        return api_response({"error": "Webcam not accessible or no frame captured."}, status="error"), 500
    return api_response(data)

@app.route('/api/biometric/emotion')
def biometric_emotion():
    _, emotions = analyze_webcam_emotion()
    if emotions is None:
        return api_response({"error": "Webcam not accessible or no frame captured."}, status="error"), 500
    return api_response({"emotions": emotions})

@app.route('/api/biometric/face')
def biometric_face():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        return api_response({"error": "Webcam not accessible."}, status="error"), 500
    ret, frame = cap.read()
    cap.release()
    if not ret:
        return api_response({"error": "No frame captured."}, status="error"), 500
    detector = FER()
    faces = detector.detect_emotions(frame)
    face_status = "present" if faces else "not detected"
    return api_response({"face_status": face_status, "face_count": len(faces)})

@app.route('/api/biometric/activity')
def biometric_activity():
    activity = get_activity()
    return api_response(activity)

@app.route('/api/biometric/custom', methods=['POST'])
def biometric_custom():
    data = request.json or {}
    return api_response(data, status="posted")

if __name__ == '__main__':
    app.run(port=5000)
from flask import Flask, jsonify
import cv2
from fer import FER

app = Flask(__name__)

def analyze_webcam_emotion():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        return None, None
    ret, frame = cap.read()
    cap.release()
    if not ret:
        return None, None
    detector = FER()
    result = detector.top_emotion(frame)
    emotions = detector.detect_emotions(frame)
    emotion, score = result if result else (None, 0)
    stressLevel = "high" if emotion in ["angry", "fear", "sad"] else "low"
    fatigueLevel = "moderate" if emotion == "sad" else "low"
    focusLevel = "low" if emotion in ["angry", "fear", "sad"] else "high"
    return {
        "stressLevel": stressLevel,
        "focusLevel": focusLevel,
        "fatigueLevel": fatigueLevel,
        "emotion": emotion,
        "score": score
    }, emotions

@app.route('/api/biometric')
def biometric():
    data, _ = analyze_webcam_emotion()
    if not data:
        return jsonify({"error": "Webcam not accessible or no frame captured."}), 500
    return jsonify(data)

@app.route('/api/biometric/emotion')
def biometric_emotion():
    _, emotions = analyze_webcam_emotion()
    if emotions is None:
        return jsonify({"error": "Webcam not accessible or no frame captured."}), 500
    return jsonify({"emotions": emotions})

@app.route('/api/biometric/face')
def biometric_face():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        return jsonify({"error": "Webcam not accessible."}), 500
    ret, frame = cap.read()
    cap.release()
    if not ret:
        return jsonify({"error": "No frame captured."}), 500
    detector = FER()
    faces = detector.detect_emotions(frame)
    face_status = "present" if faces else "not detected"
    return jsonify({"face_status": face_status, "face_count": len(faces)})

if __name__ == '__main__':
    app.run(port=5000)

from flask import Flask, jsonify
import cv2
from fer import FER

app = Flask(__name__)

def analyze_webcam_emotion():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        return None
    ret, frame = cap.read()
    cap.release()
    if not ret:
        return None
    detector = FER()
    result = detector.top_emotion(frame)
    emotion, score = result if result else (None, 0)
    stressLevel = "high" if emotion in ["angry", "fear", "sad"] else "low"
    fatigueLevel = "moderate" if emotion == "sad" else "low"
    focusLevel = "low" if emotion in ["angry", "fear", "sad"] else "high"
    return {
        "stressLevel": stressLevel,
        "focusLevel": focusLevel,
        "fatigueLevel": fatigueLevel,
        "emotion": emotion,
        "score": score
    }

@app.route('/api/biometric')
def biometric():
    data = analyze_webcam_emotion()
    if not data:
        return jsonify({"error": "Webcam not accessible or no frame captured."}), 500
    return jsonify(data)

if __name__ == '__main__':
    app.run(port=5000)
