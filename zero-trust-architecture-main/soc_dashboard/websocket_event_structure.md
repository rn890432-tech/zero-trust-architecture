# WebSocket Event Structure

## Event Types
- message_event: { id, timestamp, type, severity, message, provider, status }
- queue_update: { depth, workerHealth }
- delivery_update: { opens, clicks, bounces }
- provider_status: { name, health, failoverHistory }
- alert: { id, severity, description, timestamp }

## Example WebSocket Payload
```
{
  "type": "queue_update",
  "payload": {
    "depth": 120,
    "workerHealth": [
      { "id": "worker-1", "status": "healthy", "lastHeartbeat": "2026-03-09T12:00:00Z" },
      { "id": "worker-2", "status": "degraded", "lastHeartbeat": "2026-03-09T12:00:05Z" }
    ]
  }
}
```
