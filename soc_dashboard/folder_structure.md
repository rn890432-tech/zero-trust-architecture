# Frontend + Backend Folder Structure

## Frontend (React)
soc_dashboard/frontend/
  src/
    components/
      EventTimeline.js
      QueueGauge.js
      WorkerHealthTable.js
      DeliveryMetricsChart.js
      ProviderStatusCards.js
      AlertsPanel.js
      DrilldownDetails.js
      SearchBar.js
      RoleSelector.js
    views/
      AnalystView.js
      ExecutiveView.js
    App.js
    index.js
  public/
    index.html
  package.json

## Backend (Node.js/GraphQL/REST)
soc_dashboard/backend/
  src/
    api/
      events.js
      metrics.js
      delivery.js
      providers.js
      alerts.js
      users.js
    graphql/
      schema.js
      resolvers.js
    websocket/
      server.js
      eventPublisher.js
    db/
      postgres.js
      redis.js
      kafka.js
      prometheus.js
    auth/
      rbac.js
      session.js
    app.js
    index.js
  package.json
