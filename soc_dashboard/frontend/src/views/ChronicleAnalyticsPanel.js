import React, { useEffect, useState } from 'react';
import { fetchChronicleEvents } from '../services/api';

const ChronicleAnalyticsPanel = () => {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    fetchChronicleEvents().then(setEvents);
  }, []);
  return (
    <div>
      <h2>Google Chronicle Analytics</h2>
      <ul>
        {events.map((event, idx) => (
          <li key={idx}>{JSON.stringify(event)}</li>
        ))}
      </ul>
    </div>
  );
};

export default ChronicleAnalyticsPanel;
