# Network Architecture Diagram

```
Internet
   ↓
[Load Balancer]
   ↓
[API Gateway Pods]
   ↓
[Kafka Event Bus]
   ↓
[Worker Services]
   ↓
[Mailer Provider Layer]
   ↓
[Postgres + Redis]
   ↓
[Object Storage (S3)]

Observability:
   ↳ [Prometheus] ↳ [Grafana] ↳ [Log Aggregator]

Security:
   ↳ [Secrets Manager] ↳ [TLS Termination] ↳ [RBAC]
```

- External load balancer routes traffic to API Gateway pods
- Internal service mesh manages service-to-service communication
- Kafka handles event streaming and queue resilience
- Workers process events and messages
- Mailer provider layer abstracts email delivery and failover
- Data layer includes PostgreSQL, Redis, and S3 for attachments/logs
- Observability stack monitors metrics, logs, and alerts
- Security layer manages secrets, encryption, and access control
