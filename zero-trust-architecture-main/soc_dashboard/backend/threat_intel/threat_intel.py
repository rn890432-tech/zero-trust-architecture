from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/threat-intel', methods=['GET'])
def get_threat_intel():
    # Placeholder: Fetch threat intelligence data
    return jsonify({'status': 'ok', 'data': []})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
