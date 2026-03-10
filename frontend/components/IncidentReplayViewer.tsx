import React, { useEffect, useState } from 'react';

const IncidentReplayViewer = () => {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    // Fetch incident replay events from backend
    fetch('/api/incident_replay')
      .then(res => res.json())
      .then(data => setEvents(data));
  }, []);

  return (
    <div>
      <h2>Incident Replay</h2>
      <ul>
        {events.map((e, idx) => (
          <li key={idx}>{e.timestamp} - {e.event}</li>
        ))}
      </ul>
    </div>
  );
};

export default IncidentReplayViewer;
