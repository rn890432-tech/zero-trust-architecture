import React, { useEffect, useState } from "react";
export default function AutonomousThreatHunting() {
  const [cases, setCases] = useState([]);
  useEffect(() => {
    // Placeholder: fetch threat hunting cases from backend API
    // setCases([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Autonomous Threat Hunting</h3>
      {cases.map((c, i) => (
        <div key={i}>
          <b>Entity:</b> {c.entity}<br />
          <b>Suspicious Chain:</b> {c.chain.join(", ")}<br />
          <b>Risk Score:</b> {c.risk}<br />
          <b>Timestamp:</b> {new Date(c.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
