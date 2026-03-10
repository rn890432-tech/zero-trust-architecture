import React, { useEffect, useState } from 'react';
import { fetchAlerts } from '../services/api';

const AlertNotification = () => {
  const [newAlert, setNewAlert] = useState(null);
  useEffect(() => {
    const interval = setInterval(() => {
      fetchAlerts().then(alerts => {
        if (alerts.length > 0) {
          setNewAlert(alerts[0]);
          setTimeout(() => setNewAlert(null), 5000);
        }
      });
    }, 10000);
    return () => clearInterval(interval);
  }, []);
  return newAlert ? (
    <div className="alert-toast" style={{ position: 'fixed', top: 10, right: 10, background: 'red', color: 'white', padding: 10 }}>
      <strong>New Alert:</strong> [{newAlert.severity}] {newAlert.message}
    </div>
  ) : null;
};

export default AlertNotification;
