import React, { useEffect, useState } from "react";
export default function DarkWebIntelligence() {
  const [threats, setThreats] = useState([]);
  useEffect(() => {
    // Placeholder: fetch threats from backend API
    // setThreats([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Dark Web Intelligence</h3>
      {threats.map((t, i) => (
        <div key={i}>
          <b>Source:</b> {t.source}<br />
          <b>Severity:</b> {t.threat.severity}<br />
          <b>Indicators:</b> {JSON.stringify(t.indicators)}<br />
          <b>Actor:</b> {t.actor || "Unknown"}<br />
          <b>Timestamp:</b> {new Date(t.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
