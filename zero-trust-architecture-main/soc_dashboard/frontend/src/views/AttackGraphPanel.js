import React, { useEffect, useState } from 'react';
import { fetchAttackGraph } from '../services/api';

const AttackGraphPanel = () => {
  const [graph, setGraph] = useState(null);
  useEffect(() => {
    fetchAttackGraph().then(data => setGraph(data));
  }, []);
  return (
    <div>
      <h2>Attack Graph</h2>
      {graph ? <pre>{JSON.stringify(graph, null, 2)}</pre> : 'Loading...'}
    </div>
  );
};

export default AttackGraphPanel;
