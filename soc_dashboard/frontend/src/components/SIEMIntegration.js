import React, { useEffect, useState } from "react";
export default function SIEMIntegration() {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    // Placeholder: fetch SIEM events from backend API
    // setEvents([...]);
  }, []);
  return (
    <div className="panel">
      <h3>SIEM Integration</h3>
      {events.map((e, i) => (
        <div key={i}>
          <b>Event:</b> {JSON.stringify(e)}<br />
        </div>
      ))}
    </div>
  );
}
