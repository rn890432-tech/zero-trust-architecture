import React, { useEffect, useState } from "react";
export default function CaseManagement() {
  const [cases, setCases] = useState([]);
  useEffect(() => {
    // Placeholder: fetch cases from backend API
    // setCases([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Case Management</h3>
      {cases.map((c, i) => (
        <div key={i}>
          <b>Case ID:</b> {c.id}<br />
          <b>Alert:</b> {JSON.stringify(c.alert)}<br />
          <b>Analyst:</b> {c.analyst}<br />
          <b>Status:</b> {c.status}<br />
          <b>Actions:</b> {c.actions.map(a => a.action).join(", ")}<br />
          <b>Created:</b> {new Date(c.created * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
