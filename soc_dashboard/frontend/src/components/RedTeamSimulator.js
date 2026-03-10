import React, { useEffect, useState } from "react";
export default function RedTeamSimulator() {
  const [attacks, setAttacks] = useState([]);
  useEffect(() => {
    // Placeholder: fetch simulated attacks from backend API
    // setAttacks([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Red Team Simulator</h3>
      {attacks.map((a, i) => (
        <div key={i}>
          <b>Scenario:</b> {a.scenario}<br />
          <b>Techniques:</b> {a.path.map(p => p.technique).join(", ")}<br />
          <b>Detection Success:</b> {a.detected ? "Yes" : "No"}<br />
          <b>Response Time:</b> {a.response_time} seconds<br />
          <b>AI Detection Accuracy:</b> {Math.round(a.ai_accuracy * 100)}%<br />
        </div>
      ))}
    </div>
  );
}
