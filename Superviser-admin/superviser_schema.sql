-- Superviser tier ERD - core table definitions
-- PostgreSQL style DDL covering dashboard, organization/user management, billing, analytics, monitoring, and settings domains.

CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE IF NOT EXISTS plans (
    plan_id           BIGSERIAL PRIMARY KEY,
    plan_name         VARCHAR(64) NOT NULL UNIQUE,
    billing_cycle     VARCHAR(32) NOT NULL DEFAULT 'monthly',
    price_mrr         NUMERIC(12,2) NOT NULL DEFAULT 0,
    price_arr         NUMERIC(12,2) NOT NULL DEFAULT 0,
    features_json     JSONB,
    max_users         INTEGER,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizations (
    organization_id   BIGSERIAL PRIMARY KEY,
    name              VARCHAR(255) NOT NULL,
    plan_id           BIGINT REFERENCES plans(plan_id),
    industry          VARCHAR(64),
    company_size      VARCHAR(32),
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    joined_at         DATE NOT NULL DEFAULT CURRENT_DATE,
    trial_end_at      DATE,
    mrr               NUMERIC(12,2) NOT NULL DEFAULT 0,
    notes             TEXT,
    created_by        BIGINT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    user_id           BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    email             CITEXT NOT NULL UNIQUE,
    name              VARCHAR(255) NOT NULL,
    role              VARCHAR(64) NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    last_active_at    TIMESTAMPTZ,
    signup_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_avg_duration INTEGER,
    total_usage       BIGINT NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_roles (
    role_id           BIGSERIAL PRIMARY KEY,
    role_name         VARCHAR(64) NOT NULL UNIQUE,
    permissions_json  JSONB NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_role_assignments (
    assignment_id     BIGSERIAL PRIMARY KEY,
    user_id           BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id           BIGINT NOT NULL REFERENCES user_roles(role_id) ON DELETE CASCADE,
    assigned_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by       BIGINT
);

CREATE TABLE IF NOT EXISTS sessions (
    session_id        BIGSERIAL PRIMARY KEY,
    user_id           BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    started_at        TIMESTAMPTZ NOT NULL,
    ended_at          TIMESTAMPTZ,
    duration_sec      INTEGER,
    device_info       JSONB,
    ip_address        INET
);

CREATE TABLE IF NOT EXISTS api_usage (
    usage_id          BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    user_id           BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    provider          VARCHAR(64) NOT NULL,
    endpoint          VARCHAR(128) NOT NULL,
    tokens            BIGINT NOT NULL DEFAULT 0,
    cost              NUMERIC(12,4) NOT NULL DEFAULT 0,
    status            VARCHAR(32) NOT NULL,
    response_time_ms  INTEGER,
    requested_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS metrics_snapshot (
    snapshot_id       BIGSERIAL PRIMARY KEY,
    metric_date       DATE NOT NULL,
    metric_type       VARCHAR(64) NOT NULL,
    organization_id   BIGINT REFERENCES organizations(organization_id) ON DELETE CASCADE,
    value             NUMERIC(18,4) NOT NULL,
    dimension_json    JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cohort_metrics (
    cohort_id         BIGSERIAL PRIMARY KEY,
    cohort_month      DATE NOT NULL,
    metric_type       VARCHAR(64) NOT NULL,
    month_offset      INTEGER NOT NULL,
    value             NUMERIC(18,4) NOT NULL
);

CREATE TABLE IF NOT EXISTS growth_channels (
    channel_id        BIGSERIAL PRIMARY KEY,
    channel_name      VARCHAR(64) NOT NULL UNIQUE,
    description       TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_acquisition (
    acquisition_id    BIGSERIAL PRIMARY KEY,
    user_id           BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    channel_id        BIGINT NOT NULL REFERENCES growth_channels(channel_id) ON DELETE SET NULL,
    acquired_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    campaign_info     JSONB
);

CREATE TABLE IF NOT EXISTS feedback (
    feedback_id       BIGSERIAL PRIMARY KEY,
    user_id           BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    organization_id   BIGINT REFERENCES organizations(organization_id) ON DELETE SET NULL,
    category          VARCHAR(64),
    rating            INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment           TEXT,
    submitted_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id    BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    plan_id           BIGINT REFERENCES plans(plan_id),
    amount            NUMERIC(12,2) NOT NULL,
    currency          VARCHAR(8) NOT NULL DEFAULT 'USD',
    status            VARCHAR(32) NOT NULL,
    payment_method    VARCHAR(64),
    transaction_type  VARCHAR(32) NOT NULL DEFAULT 'subscription',
    transacted_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    invoice_url       TEXT
);

CREATE TABLE IF NOT EXISTS invoices (
    invoice_id        BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    billing_period_start DATE NOT NULL,
    billing_period_end   DATE NOT NULL,
    total_amount      NUMERIC(12,2) NOT NULL,
    status            VARCHAR(32) NOT NULL,
    issued_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_at            TIMESTAMPTZ,
    paid_at           TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS subscription_changes (
    change_id         BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    old_plan_id       BIGINT REFERENCES plans(plan_id),
    new_plan_id       BIGINT REFERENCES plans(plan_id),
    effective_at      TIMESTAMPTZ NOT NULL,
    reason            VARCHAR(255),
    changed_by        BIGINT
);

CREATE TABLE IF NOT EXISTS arpu_history (
    record_id         BIGSERIAL PRIMARY KEY,
    period            DATE NOT NULL,
    arpu_value        NUMERIC(12,4) NOT NULL,
    plan_id           BIGINT REFERENCES plans(plan_id)
);

CREATE TABLE IF NOT EXISTS reports (
    report_id         BIGSERIAL PRIMARY KEY,
    name              VARCHAR(128) NOT NULL,
    type              VARCHAR(64) NOT NULL,
    description       TEXT,
    definition_json   JSONB NOT NULL,
    created_by        BIGINT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scheduled_reports (
    schedule_id       BIGSERIAL PRIMARY KEY,
    report_id         BIGINT NOT NULL REFERENCES reports(report_id) ON DELETE CASCADE,
    frequency         VARCHAR(32) NOT NULL,
    recipients        TEXT NOT NULL,
    next_run_at       TIMESTAMPTZ,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    last_run_at       TIMESTAMPTZ,
    created_by        BIGINT
);

CREATE TABLE IF NOT EXISTS report_runs (
    run_id            BIGSERIAL PRIMARY KEY,
    report_id         BIGINT NOT NULL REFERENCES reports(report_id) ON DELETE CASCADE,
    schedule_id       BIGINT REFERENCES scheduled_reports(schedule_id) ON DELETE SET NULL,
    run_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status            VARCHAR(32) NOT NULL,
    generated_file_url TEXT,
    summary           TEXT
);

CREATE TABLE IF NOT EXISTS system_metrics (
    metric_id         BIGSERIAL PRIMARY KEY,
    metric_type       VARCHAR(64) NOT NULL,
    resource          VARCHAR(128) NOT NULL,
    value             NUMERIC(18,4) NOT NULL,
    unit              VARCHAR(32),
    recorded_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tags_json         JSONB
);

CREATE TABLE IF NOT EXISTS service_status (
    status_id         BIGSERIAL PRIMARY KEY,
    service_name      VARCHAR(128) NOT NULL,
    status            VARCHAR(32) NOT NULL,
    message           TEXT,
    checked_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
    alert_id          BIGSERIAL PRIMARY KEY,
    category          VARCHAR(64) NOT NULL,
    severity          VARCHAR(32) NOT NULL,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    status            VARCHAR(32) NOT NULL DEFAULT 'open',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at       TIMESTAMPTZ,
    resolved_by       BIGINT
);

CREATE TABLE IF NOT EXISTS events (
    event_id          BIGSERIAL PRIMARY KEY,
    source            VARCHAR(128) NOT NULL,
    level             VARCHAR(32) NOT NULL,
    message           TEXT NOT NULL,
    metadata_json     JSONB,
    occurred_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS logs (
    log_id            BIGSERIAL PRIMARY KEY,
    service_name      VARCHAR(128) NOT NULL,
    level             VARCHAR(32) NOT NULL,
    message           TEXT NOT NULL,
    context_json      JSONB,
    logged_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS platform_settings (
    setting_id        BIGSERIAL PRIMARY KEY,
    category          VARCHAR(64) NOT NULL,
    key               VARCHAR(128) NOT NULL,
    value             TEXT,
    value_type        VARCHAR(32) NOT NULL,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by        BIGINT,
    UNIQUE(category, key)
);

CREATE TABLE IF NOT EXISTS api_keys (
    api_key_id        BIGSERIAL PRIMARY KEY,
    name              VARCHAR(128) NOT NULL,
    key_hash          TEXT NOT NULL UNIQUE,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by        BIGINT,
    revoked_at        TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS rate_limits (
    limit_id          BIGSERIAL PRIMARY KEY,
    plan_id           BIGINT REFERENCES plans(plan_id) ON DELETE CASCADE,
    limit_type        VARCHAR(64) NOT NULL,
    limit_value       INTEGER NOT NULL,
    window_sec        INTEGER NOT NULL,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by        BIGINT
);

CREATE TABLE IF NOT EXISTS webhooks (
    webhook_id        BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT REFERENCES organizations(organization_id) ON DELETE CASCADE,
    event_type        VARCHAR(64) NOT NULL,
    target_url        TEXT NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    secret            TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS llm_providers (
    provider_id       BIGSERIAL PRIMARY KEY,
    provider_name     VARCHAR(64) NOT NULL,
    api_key           TEXT NOT NULL,
    default_model     VARCHAR(128),
    temperature       NUMERIC(4,2),
    max_tokens        INTEGER,
    last_tested_at    TIMESTAMPTZ,
    status            VARCHAR(32) NOT NULL DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS email_settings (
    email_setting_id  BIGSERIAL PRIMARY KEY,
    smtp_host         VARCHAR(255) NOT NULL,
    smtp_port         INTEGER NOT NULL,
    tls_enabled       BOOLEAN NOT NULL DEFAULT TRUE,
    username          VARCHAR(255),
    password_encrypted TEXT,
    sender_name       VARCHAR(128),
    sender_email      VARCHAR(255),
    reply_to          VARCHAR(255),
    template_config_json JSONB,
    last_tested_at    TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS integrations (
    integration_id    BIGSERIAL PRIMARY KEY,
    type              VARCHAR(64) NOT NULL,
    config_json       JSONB NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    last_tested_at    TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS backups (
    backup_id         BIGSERIAL PRIMARY KEY,
    frequency         VARCHAR(32) NOT NULL,
    time_utc          TIME NOT NULL,
    retention_period  VARCHAR(32) NOT NULL,
    storage_type      VARCHAR(32) NOT NULL,
    config_json       JSONB,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    last_run_at       TIMESTAMPTZ,
    next_run_at       TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS backup_history (
    history_id        BIGSERIAL PRIMARY KEY,
    backup_id         BIGINT NOT NULL REFERENCES backups(backup_id) ON DELETE CASCADE,
    run_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    type              VARCHAR(32),
    size              NUMERIC(18,4),
    status            VARCHAR(32) NOT NULL,
    location          TEXT,
    notes             TEXT
);

CREATE TABLE IF NOT EXISTS env_variables (
    env_id            BIGSERIAL PRIMARY KEY,
    key               VARCHAR(128) NOT NULL UNIQUE,
    value             TEXT,
    scope             VARCHAR(64) NOT NULL,
    encrypted         BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by        BIGINT
);

CREATE TABLE IF NOT EXISTS danger_zone_logs (
    action_id         BIGSERIAL PRIMARY KEY,
    action_type       VARCHAR(64) NOT NULL,
    performed_by      BIGINT,
    performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes             TEXT
);

CREATE TABLE IF NOT EXISTS feature_toggles (
    toggle_id         BIGSERIAL PRIMARY KEY,
    feature_name      VARCHAR(128) NOT NULL UNIQUE,
    is_enabled        BOOLEAN NOT NULL DEFAULT FALSE,
    scope             VARCHAR(64),
    description       TEXT,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by        BIGINT
);

CREATE TABLE IF NOT EXISTS usage_features (
    record_id         BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    feature_name      VARCHAR(128) NOT NULL,
    usage_count       BIGINT NOT NULL DEFAULT 0,
    period            DATE NOT NULL,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (organization_id, feature_name, period)
);

CREATE TABLE IF NOT EXISTS ai_insights (
    insight_id        BIGSERIAL PRIMARY KEY,
    category          VARCHAR(64) NOT NULL,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    data_points_json  JSONB,
    generated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS forecasts (
    forecast_id       BIGSERIAL PRIMARY KEY,
    metric_type       VARCHAR(64) NOT NULL,
    period            DATE NOT NULL,
    value             NUMERIC(18,4) NOT NULL,
    model_info        JSONB,
    generated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confidence_interval_json JSONB
);

-- Indexes to support frequent queries
CREATE INDEX IF NOT EXISTS idx_organizations_plan ON organizations(plan_id);
CREATE INDEX IF NOT EXISTS idx_users_org ON users(organization_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_org_requested ON api_usage(organization_id, requested_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_org_date ON transactions(organization_id, transacted_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_system_metrics_type_time ON system_metrics(metric_type, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_status_service ON service_status(service_name, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_webhooks_org_event ON webhooks(organization_id, event_type);
CREATE INDEX IF NOT EXISTS idx_usage_features_period ON usage_features(period);
