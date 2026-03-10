import React from 'react';

const SummaryCards = ({ metrics }) => (
  <div className="summary-cards">
    <div className="card" style={{ background: 'red' }}>
      <h4>Total Alerts</h4>
      <span>{metrics.alerts}</span>
    </div>
    <div className="card" style={{ background: 'green' }}>
      <h4>Compliance Rate</h4>
      <span>{metrics.compliance}%</span>
    </div>
    <div className="card" style={{ background: 'orange' }}>
      <h4>Risk Score</h4>
      <span>{metrics.risk}</span>
    </div>
  </div>
);

export default SummaryCards;
