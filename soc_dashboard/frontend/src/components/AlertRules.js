import React, { useEffect, useState } from "react";
export default function AlertRules() {
  const [alerts, setAlerts] = useState([]);
  useEffect(() => {
    // Placeholder: fetch alerts from backend API
    // setAlerts([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Custom Alert Rules</h3>
      {alerts.map((a, i) => (
        <div key={i}>
          <b>Event:</b> {JSON.stringify(a.event)}<br />
          <b>Rule:</b> {a.rule}<br />
          <b>Timestamp:</b> {new Date(a.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
