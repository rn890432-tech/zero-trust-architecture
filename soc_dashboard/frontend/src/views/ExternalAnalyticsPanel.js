import React, { useEffect, useState } from 'react';
import { fetchSplunkEvents } from '../services/api';

const ExternalAnalyticsPanel = () => {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    fetchSplunkEvents().then(setEvents);
  }, []);
  return (
    <div>
      <h2>Splunk Analytics</h2>
      <ul>
        {events.map((event, idx) => (
          <li key={idx}>{JSON.stringify(event)}</li>
        ))}
      </ul>
    </div>
  );
};

export default ExternalAnalyticsPanel;
