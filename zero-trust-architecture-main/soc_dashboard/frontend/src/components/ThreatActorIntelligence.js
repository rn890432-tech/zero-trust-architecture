import React, { useEffect, useState } from "react";
export default function ThreatActorIntelligence() {
  const [attribution, setAttribution] = useState(null);
  useEffect(() => {
    // Placeholder: fetch attribution from backend API
    // setAttribution({...});
  }, []);
  return (
    <div className="panel">
      <h3>Threat Actor Intelligence</h3>
      {attribution ? (
        <div>
          <b>Suspected Actor:</b> {attribution.actor}<br />
          <b>Confidence Score:</b> {attribution.score}<br />
          <b>Campaigns:</b> {attribution.campaigns.join(", ")}<br />
          <b>Techniques:</b> {attribution.techniques.join(", ")}<br />
          <b>Infrastructure:</b> {attribution.infrastructure.join(", ")}<br />
        </div>
      ) : (
        <div>No attribution data available.</div>
      )}
    </div>
  );
}
