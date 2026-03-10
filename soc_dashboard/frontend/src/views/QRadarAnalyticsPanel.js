import React, { useEffect, useState } from 'react';
import { fetchQRadarEvents } from '../services/api';

const QRadarAnalyticsPanel = () => {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    fetchQRadarEvents().then(setEvents);
  }, []);
  return (
    <div>
      <h2>IBM QRadar Analytics</h2>
      <ul>
        {events.map((event, idx) => (
          <li key={idx}>{JSON.stringify(event)}</li>
        ))}
      </ul>
    </div>
  );
};

export default QRadarAnalyticsPanel;
