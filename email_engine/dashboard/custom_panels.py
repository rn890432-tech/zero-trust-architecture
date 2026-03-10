# Custom Dashboard Panels (tenant stats, advanced metrics)
from flask import Blueprint, jsonify

custom_panels = Blueprint('custom_panels', __name__)

@custom_panels.route('/api/tenant_stats')
def tenant_stats():
    # Simulated tenant stats
    stats = {
        'TenantA': {'sent': 500, 'opens': 300, 'clicks': 100},
        'TenantB': {'sent': 700, 'opens': 500, 'clicks': 200}
    }
    return jsonify(stats)

@custom_panels.route('/api/advanced_metrics')
def advanced_metrics():
    # Simulated advanced metrics
    metrics = {
        'device_distribution': {'mobile': 60, 'desktop': 40},
        'geo_distribution': {'US': 70, 'EU': 20, 'APAC': 10}
    }
    return jsonify(metrics)
