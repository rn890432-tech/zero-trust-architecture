import React, { useEffect, useState } from 'react';
import { fetchAnomalies, fetchRiskScores, fetchIncidentTrends } from '../services/api';
import IncidentTrendChart from '../components/IncidentTrendChart';
import ComplianceStatusChart from '../components/ComplianceStatusChart';
import UserBehaviorChart from '../components/UserBehaviorChart';
import AlertWidget from '../components/AlertWidget';

const AnalyticsPanel = () => {
  const [anomalies, setAnomalies] = useState([]);
  const [riskScores, setRiskScores] = useState([]);
  const [incidentTrends, setIncidentTrends] = useState([]);
  const [compliance, setCompliance] = useState([]);
  const [userBehavior, setUserBehavior] = useState([]);

  useEffect(() => {
    fetchAnomalies().then(setAnomalies);
    fetchRiskScores().then(setRiskScores);
    fetchIncidentTrends().then(setIncidentTrends);
    // Add fetchCompliance and fetchUserBehavior API calls
    if (typeof fetchCompliance === 'function') fetchCompliance().then(setCompliance);
    if (typeof fetchUserBehavior === 'function') fetchUserBehavior().then(setUserBehavior);
  }, []);

  return (
    <div>
      <h2>Custom Analytics</h2>
      <AlertWidget />
      <h3>Anomalies</h3>
      <ul>
        {anomalies.map((a, idx) => (
          <li key={idx}>{a.type} - {a.user} (score: {a.score})</li>
        ))}
      </ul>
      <h3>Risk Scores</h3>
      <ul>
        {riskScores.map((r, idx) => (
          <li key={idx}>{r.asset} (risk: {r.risk})</li>
        ))}
      </ul>
      <h3>Incident Trends</h3>
      <IncidentTrendChart data={incidentTrends} />
      <h3>Compliance Status</h3>
      <ComplianceStatusChart data={compliance} />
      <h3>User Behavior</h3>
      <UserBehaviorChart data={userBehavior} />
    </div>
  );
};

export default AnalyticsPanel;
