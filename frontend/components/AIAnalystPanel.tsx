import React, { useEffect, useState } from 'react';

const AIAnalystPanel = () => {
  const [analysis, setAnalysis] = useState([]);

  useEffect(() => {
    fetch('/api/ai_analysis')
      .then(res => res.json())
      .then(data => setAnalysis(data));
  }, []);

  return (
    <div>
      <h2>AI Analyst Panel</h2>
      <ul>
        {analysis.map((incident, idx) => (
          <li key={idx}>
            <strong>Summary:</strong> {incident.incident_summary}<br />
            <strong>Recommendation:</strong> {incident.recommended_action}<br />
            <strong>Priority:</strong> {incident.priority}<br />
            <strong>Confidence:</strong> {incident.confidence_score}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default AIAnalystPanel;
