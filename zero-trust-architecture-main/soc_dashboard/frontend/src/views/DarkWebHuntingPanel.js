import React, { useEffect, useState } from 'react';
import { fetchDarkWebFindings } from '../services/api';

const DarkWebHuntingPanel = () => {
  const [findings, setFindings] = useState([]);
  useEffect(() => {
    fetchDarkWebFindings().then(data => setFindings(data));
  }, []);
  return (
    <div>
      <h2>Dark Web Hunting</h2>
      <ul>
        {findings.map((item, idx) => (
          <li key={idx}>{item}</li>
        ))}
      </ul>
    </div>
  );
};

export default DarkWebHuntingPanel;
