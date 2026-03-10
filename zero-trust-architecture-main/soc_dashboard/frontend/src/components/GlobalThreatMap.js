import React, { useEffect, useState } from "react";
// Placeholder for Three.js globe visualization
export default function GlobalThreatMap() {
  const [attacks, setAttacks] = useState([]);
  useEffect(() => {
    // Placeholder: fetch live attacks from backend API
    // setAttacks([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Global Cyber Threat Map</h3>
      {/* Globe visualization would go here */}
      {attacks.map((a, i) => (
        <div key={i}>
          <b>Source:</b> {a.source} ({a.source_ip})<br />
          <b>Target:</b> {a.target} ({a.target_ip})<br />
          <b>Type:</b> {a.type}<br />
          <b>Timestamp:</b> {new Date(a.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
