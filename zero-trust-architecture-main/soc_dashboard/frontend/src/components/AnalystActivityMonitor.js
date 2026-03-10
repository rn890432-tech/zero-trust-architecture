import React, { useEffect, useState } from "react";
export default function AnalystActivityMonitor() {
  const [activities, setActivities] = useState([]);
  useEffect(() => {
    // Placeholder: fetch activities from backend API
    // setActivities([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Analyst Activity Monitor</h3>
      {activities.map((a, i) => (
        <div key={i}>
          <b>Analyst:</b> {a.analyst}<br />
          <b>Activity:</b> {a.activity}<br />
          <b>Timestamp:</b> {new Date(a.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
