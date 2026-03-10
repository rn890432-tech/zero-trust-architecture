# Service Deployment Topology

## Namespaces
- api-gateway
- worker-services
- mailer-provider
- messaging
- observability

## Deployments
- API Gateway: Handles external requests, routes to Kafka
- Worker Services: Processes events/messages from Kafka
- Mailer Provider: Abstracts email delivery, manages failover
- Kafka: Event bus for streaming and queue resilience
- Redis: Fast queue operations and caching
- Postgres: Core data storage
- Prometheus: Metrics collection
- Grafana: Dashboard visualization
- Log Aggregator: Centralized log collection

## Autoscaling
- API Gateway, Worker, Mailer Provider: Horizontal Pod Autoscaling
- Kafka, Redis, Postgres: Replicated for resilience

## Security
- TLS termination at load balancer
- Secrets managed via Kubernetes Secrets/AWS Secrets Manager
- RBAC for service access

## CI/CD
- Automated builds and container registry
- Helm charts for deployment
- Environment promotion: dev → staging → production
