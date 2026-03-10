# API Contracts for Dashboard Data

## REST Endpoints
- GET /events/live: Returns real-time message events (Kafka/Redis)
- GET /metrics/queue: Returns queue depth, worker health (Prometheus)
- GET /metrics/delivery: Returns opens, clicks, bounces (DB)
- GET /providers/status: Returns provider health, failover history
- GET /alerts: Returns active alerts, SLA breaches, delivery spikes
- GET /users/me: Returns user role and permissions

## GraphQL Schema
```
type Event {
  id: ID!
  timestamp: String!
  type: String!
  severity: String!
  message: String!
  provider: String
  status: String
}
type QueueMetrics {
  depth: Int!
  workerHealth: [WorkerHealth!]!
}
type WorkerHealth {
  id: ID!
  status: String!
  lastHeartbeat: String!
}
type DeliveryMetrics {
  opens: Int!
  clicks: Int!
  bounces: Int!
}
type ProviderStatus {
  name: String!
  health: String!
  failoverHistory: [FailoverEvent!]!
}
type Alert {
  id: ID!
  severity: String!
  description: String!
  timestamp: String!
}
type User {
  id: ID!
  role: String!
  permissions: [String!]!
}
```
