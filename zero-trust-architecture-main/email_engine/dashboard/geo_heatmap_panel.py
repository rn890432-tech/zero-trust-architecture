from flask import Blueprint, jsonify

geo_heatmap_panel = Blueprint('geo_heatmap_panel', __name__)

@geo_heatmap_panel.route('/api/geo-heatmap')
def get_geo_heatmap():
    return jsonify({"regions": {"US": 800, "EU": 300, "Asia": 100}, "heatmap": [[37.7749, -122.4194, 800], [48.8566, 2.3522, 300], [35.6895, 139.6917, 100]]})
