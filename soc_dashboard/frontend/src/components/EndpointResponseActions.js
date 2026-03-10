import React, { useEffect, useState } from "react";
export default function EndpointResponseActions() {
  const [actions, setActions] = useState([]);
  useEffect(() => {
    // Placeholder: fetch endpoint actions from backend API
    // setActions([...]);
  }, []);
  return (
    <div className="panel">
      <h3>Endpoint Response Actions</h3>
      {actions.map((a, i) => (
        <div key={i}>
          <b>Action:</b> {a.action}<br />
          <b>Target:</b> {a.endpoint || a.user || a.domain}<br />
          <b>Timestamp:</b> {new Date(a.timestamp * 1000).toLocaleString()}<br />
        </div>
      ))}
    </div>
  );
}
