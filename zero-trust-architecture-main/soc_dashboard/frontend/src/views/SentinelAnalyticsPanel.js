import React, { useEffect, useState } from 'react';
import { fetchSentinelEvents } from '../services/api';

const SentinelAnalyticsPanel = () => {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    fetchSentinelEvents().then(setEvents);
  }, []);
  return (
    <div>
      <h2>Azure Sentinel Analytics</h2>
      <ul>
        {events.map((event, idx) => (
          <li key={idx}>{JSON.stringify(event)}</li>
        ))}
      </ul>
    </div>
  );
};

export default SentinelAnalyticsPanel;
