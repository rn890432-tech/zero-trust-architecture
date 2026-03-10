from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/attack-graph', methods=['GET'])
def get_attack_graph():
    # Placeholder: Generate attack graph
    return jsonify({'status': 'ok', 'graph': {}})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
