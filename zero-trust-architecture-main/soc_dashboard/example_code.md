# Example Code for Fetching and Displaying Live Metrics

## Frontend (React)
```js
// src/components/QueueGauge.js
import React, { useEffect, useState } from 'react';
const QueueGauge = () => {
  const [depth, setDepth] = useState(0);
  useEffect(() => {
    const ws = new WebSocket('wss://your-backend/ws');
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
```

## Backend (Node.js/Express)
```js
// src/api/metrics.js
const express = require('express');
const router = express.Router();
router.get('/queue', async (req, res) => {
  // Fetch queue depth from Prometheus or Redis
  const depth = await getQueueDepth();
  res.json({ depth });
});
module.exports = router;
```

## WebSocket Server
```js
// src/websocket/server.js
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });
wss.on('connection', (ws) => {
  ws.on('message', (message) => {
    // Handle incoming messages
  });
  // Send queue updates
  setInterval(() => {
    ws.send(JSON.stringify({
      type: 'queue_update',
      payload: { depth: getQueueDepth() }
    }));
  }, 1000);
});
```
