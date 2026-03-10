import React, { useEffect, useState } from "react";
export default function AutomatedReporting() {
  const [reports, setReports] = useState([]);
  useEffect(() => {
    // Placeholder: fetch reports from backend API
    // setReports([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Automated Reporting</h3>
      {reports.map((r, i) => (
        <div key={i}>
          <b>Timestamp:</b> {new Date(r.timestamp * 1000).toLocaleString()}<br />
          <b>Incidents:</b> {r.incidents}<br />
          <b>Cases:</b> {r.cases}<br />
          <b>Details:</b> {JSON.stringify(r.details)}<br />
        </div>
      ))}
    </div>
  );
}
