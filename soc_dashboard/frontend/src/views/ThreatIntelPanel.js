import React, { useEffect, useState } from 'react';
import { fetchThreatFeed } from '../services/api';

const ThreatIntelPanel = () => {
  const [feed, setFeed] = useState([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    fetchThreatFeed().then(data => {
      setFeed(data);
      setLoading(false);
    });
  }, []);
  return (
    <div>
      <h2>Threat Intelligence</h2>
      {loading ? <div>Loading...</div> : (
        <table>
          <thead>
            <tr>
              <th>Indicator</th>
              <th>Type</th>
              <th>Source</th>
            </tr>
          </thead>
          <tbody>
            {feed.map((item, idx) => (
              <tr key={idx}>
                <td>{item.indicator}</td>
                <td>{item.type}</td>
                <td>{item.source}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default ThreatIntelPanel;
