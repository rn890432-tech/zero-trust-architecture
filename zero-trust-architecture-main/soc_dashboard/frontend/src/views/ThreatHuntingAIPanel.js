import React, { useEffect, useState } from 'react';
import { fetchThreatHuntingAI } from '../services/api';

const ThreatHuntingAIPanel = () => {
  const [results, setResults] = useState([]);
  useEffect(() => {
    fetchThreatHuntingAI().then(data => setResults(data));
  }, []);
  return (
    <div>
      <h2>Threat Hunting AI</h2>
      <ul>
        {results.map((item, idx) => (
          <li key={idx}>{item}</li>
        ))}
      </ul>
    </div>
  );
};

export default ThreatHuntingAIPanel;
