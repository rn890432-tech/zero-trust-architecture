import React, { useEffect, useState } from 'react';

const GlobalAttackMap = () => {
  const [attacks, setAttacks] = useState([]);

  useEffect(() => {
    const ws = new WebSocket('ws://localhost:8765');
    ws.onmessage = (event) => {
      setAttacks((prev) => [...prev, JSON.parse(event.data)]);
    };
    return () => ws.close();
  }, []);

  return (
    <div>
      <h2>Global Attack Map</h2>
      <ul>
        {attacks.map((attack, idx) => (
          <li key={idx}>
            {attack.country_from} → {attack.country_to} | {attack.source.lat},{attack.source.lon} → {attack.target.lat},{attack.target.lon}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default GlobalAttackMap;
