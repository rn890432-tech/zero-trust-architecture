import React, { useEffect, useState } from "react";
export default function IncidentQueue() {
  const [queue, setQueue] = useState([]);
  useEffect(() => {
    // Placeholder: fetch incident queue from backend API
    // setQueue([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Incident Queue</h3>
      {queue.map((q, i) => (
        <div key={i}>
          <b>Incident:</b> {JSON.stringify(q.incident)}<br />
          <b>Status:</b> {q.status}<br />
          <b>Timestamp:</b> {new Date(q.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
