import React, { useEffect, useState } from 'react';
import { fetchElasticEvents } from '../services/api';

const ElasticAnalyticsPanel = () => {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    fetchElasticEvents().then(setEvents);
  }, []);
  return (
    <div>
      <h2>Elastic Analytics</h2>
      <ul>
        {events.map((event, idx) => (
          <li key={idx}>{JSON.stringify(event)}</li>
        ))}
      </ul>
    </div>
  );
};

export default ElasticAnalyticsPanel;
