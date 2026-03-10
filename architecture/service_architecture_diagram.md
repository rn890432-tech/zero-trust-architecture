# Service-to-Service Architecture Diagram

```
Internet
   ↓
[Load Balancer]
   ↓
[API Gateway]
   ↓
[Message Ingestion Service]
   ↓
[Kafka/Redis Streams]
   ↓
[Queue Workers]
   ↓
[Mailer Provider Layer]
   ↓
[Compliance/Analytics]
   ↓
[Postgres/Redis]
   ↓
[Object Storage (S3)]

Observability:
   ↳ [Prometheus] ↳ [Grafana] ↳ [Event Logging]

Security:
   ↳ [Secrets Manager] ↳ [TLS Termination] ↳ [RBAC]
```
