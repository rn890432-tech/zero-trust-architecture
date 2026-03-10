from flask import Blueprint, request, jsonify

user_management_panel = Blueprint('user_management_panel', __name__)

users = [
    {"id": 1, "name": "Alice", "role": "admin"},
    {"id": 2, "name": "Bob", "role": "user"}
]

@user_management_panel.route('/api/users', methods=['GET'])
def get_users():
    return jsonify(users)

@user_management_panel.route('/api/users', methods=['POST'])
def add_user():
    global users
    data = request.json
    if data.get('edit'):
        for u in users:
            if u['id'] == data['id']:
                u['name'] = data['name']
                u['role'] = data['role']
        return jsonify({"status": "edited"})
    elif data.get('delete'):
        users = [u for u in users if u['id'] != data['id']]
        return jsonify({"status": "deleted"})
    else:
        users.append({"id": data['id'], "name": data['name'], "role": data['role']})
        return jsonify({"status": "added"})
