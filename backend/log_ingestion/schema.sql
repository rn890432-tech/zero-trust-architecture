CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    tenant_name TEXT,
    domain TEXT,
    subscription_plan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    email TEXT,
    role TEXT,
    password_hash TEXT
);

CREATE TABLE security_events (
    id SERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    timestamp TIMESTAMP,
    event_type TEXT,
    source_ip TEXT,
    destination_ip TEXT,
    user_id TEXT,
    asset TEXT,
    severity INT,
    raw_event JSONB
);

CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    timestamp TIMESTAMP,
    alert_type TEXT,
    severity TEXT,
    source_ip TEXT,
    target_user TEXT,
    details JSONB
);

CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    plan TEXT,
    status TEXT,
    started_at TIMESTAMP,
    ends_at TIMESTAMP
);

CREATE TABLE api_keys (
    id SERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    api_key TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
