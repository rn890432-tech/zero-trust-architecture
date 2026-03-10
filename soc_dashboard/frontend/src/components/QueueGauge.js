import React, { useEffect, useState } from 'react';
const QueueGauge = () => {
  const [depth, setDepth] = useState(0);
  useEffect(() => {
    const ws = new WebSocket('ws://localhost:8080');
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'queue_update') {
        setDepth(data.payload.depth);
      }
    };
    return () => ws.close();
  }, []);
  return <div>Queue Depth: {depth}</div>;
};
export default QueueGauge;
