# API Contracts (REST/GraphQL)

## REST Endpoints
POST /api/messages: Ingest new message
GET /api/events/live: Fetch live message events
GET /api/metrics/queue: Get queue depth, worker health
GET /api/metrics/delivery: Get delivery metrics
GET /api/providers/status: Get provider health/failover
GET /api/alerts: Get alert notifications
GET /api/compliance/suppression: Get suppression lists

## GraphQL Schema
```
type Message {
  id: ID!
  content: String!
  status: String!
  provider: String
  events: [MessageEvent!]
}
type MessageEvent {
  id: ID!
  timestamp: String!
  type: String!
  severity: String!
  message: String!
}
type QueueMetrics {
  depth: Int!
  workerHealth: [WorkerHealth!]!
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
type Compliance {
  suppressionLists: [SuppressionList!]!
  optInStatus: Boolean!
}
```
