from flask import Flask, request, jsonify
from integrations.threat_feed_integration import fetch_threat_feed
from integrations.endpoint_api_integration import query_endpoint_status, isolate_endpoint, remediate_endpoint
from integrations.siem_integration import send_to_siem

app = Flask(__name__)

@app.route('/api/messages', methods=['POST'])
def ingest_message():
    # Message ingestion logic
    return jsonify({'status': 'received'})

@app.route('/api/events/live', methods=['GET'])
def live_events():
    # Fetch live events from Kafka/Redis
    return jsonify({'events': []})

# --- SOC API integrations ---
@app.route('/api/threat-feed', methods=['GET'])
def api_threat_feed():
    return jsonify(fetch_threat_feed())

@app.route('/api/endpoint/<endpoint_id>/status', methods=['GET'])
def api_endpoint_status(endpoint_id):
    return jsonify(query_endpoint_status(endpoint_id))

@app.route('/api/endpoint/<endpoint_id>/isolate', methods=['POST'])
def api_isolate_endpoint(endpoint_id):
    return jsonify(isolate_endpoint(endpoint_id))

@app.route('/api/endpoint/<endpoint_id>/remediate', methods=['POST'])
def api_remediate_endpoint(endpoint_id):
    return jsonify(remediate_endpoint(endpoint_id))

@app.route('/api/siem', methods=['POST'])
def api_send_to_siem():
    event = request.json
    send_to_siem(event)
    return jsonify({'status': 'sent'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
