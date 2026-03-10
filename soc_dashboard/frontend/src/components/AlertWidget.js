import React, { useEffect, useState } from 'react';
import { fetchAlerts } from '../services/api';

const AlertWidget = () => {
  const [alerts, setAlerts] = useState([]);
  useEffect(() => {
    fetchAlerts().then(setAlerts);
  }, []);
  return (
    <div className="alert-widget">
      <h3>Active Alerts</h3>
      <ul>
        {alerts.map((alert, idx) => (
          <li key={idx} style={{ color: alert.severity === 'high' ? 'red' : 'orange' }}>
            [{alert.severity}] {alert.message}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default AlertWidget;
