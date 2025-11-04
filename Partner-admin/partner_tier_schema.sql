-- Partner tier conceptual schema for ERD
-- Defines core operational, analytics, finance, and security tables.

CREATE TABLE partners (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    timezone TEXT NOT NULL DEFAULT 'UTC',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE partner_users (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'partner_admin',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (partner_id, email)
);

CREATE TABLE projects (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planning',
    contract_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    expected_student_count INTEGER,
    start_date DATE,
    end_date DATE,
    description TEXT,
    created_by BIGINT REFERENCES partner_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_settings (
    project_id BIGINT PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE,
    auto_approve_students BOOLEAN NOT NULL DEFAULT FALSE,
    allow_self_registration BOOLEAN NOT NULL DEFAULT TRUE,
    default_project_duration INTERVAL,
    auto_prune_inactive BOOLEAN NOT NULL DEFAULT FALSE,
    inactive_days_threshold INTEGER DEFAULT 60,
    updated_by BIGINT REFERENCES partner_users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_staff (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    partner_user_id BIGINT NOT NULL REFERENCES partner_users(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    joined_at TIMESTAMPTZ,
    UNIQUE (project_id, partner_user_id)
);

CREATE TABLE students (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    primary_contact TEXT,
    notes TEXT
);

CREATE TABLE enrollments (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active',
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    progress_percent NUMERIC(5,2) NOT NULL DEFAULT 0,
    UNIQUE (project_id, student_id)
);

CREATE TABLE ai_sessions (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    student_id BIGINT REFERENCES students(id) ON DELETE SET NULL,
    mode TEXT NOT NULL CHECK (mode IN ('single', 'parallel')),
    model_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    total_messages INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER NOT NULL DEFAULT 0,
    total_cost NUMERIC(14,4) NOT NULL DEFAULT 0,
    initiated_by BIGINT REFERENCES partner_users(id)
);

CREATE TABLE session_messages (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL REFERENCES ai_sessions(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('student', 'staff', 'system')),
    sender_id BIGINT,
    message_type TEXT NOT NULL DEFAULT 'text',
    content TEXT NOT NULL,
    tokens INTEGER,
    latency_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE comparison_runs (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    student_id BIGINT REFERENCES students(id) ON DELETE SET NULL,
    initiated_by BIGINT REFERENCES partner_users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'running',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE TABLE comparison_run_items (
    id BIGSERIAL PRIMARY KEY,
    run_id BIGINT NOT NULL REFERENCES comparison_runs(id) ON DELETE CASCADE,
    model_name TEXT NOT NULL,
    prompt_template_version_id BIGINT REFERENCES prompt_template_versions(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    total_tokens INTEGER,
    average_latency_ms INTEGER,
    total_cost NUMERIC(14,4),
    UNIQUE (run_id, model_name)
);

CREATE TABLE usage_events_llm (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES ai_sessions(id) ON DELETE SET NULL,
    model_name TEXT NOT NULL,
    tokens_prompt INTEGER NOT NULL DEFAULT 0,
    tokens_completion INTEGER NOT NULL DEFAULT 0,
    total_cost NUMERIC(14,4) NOT NULL DEFAULT 0,
    success BOOLEAN NOT NULL DEFAULT TRUE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE usage_events_stt (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES ai_sessions(id) ON DELETE SET NULL,
    provider TEXT NOT NULL,
    media_duration_seconds INTEGER NOT NULL DEFAULT 0,
    total_cost NUMERIC(14,4) NOT NULL DEFAULT 0,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE usage_daily (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL,
    total_sessions INTEGER NOT NULL DEFAULT 0,
    total_messages INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER NOT NULL DEFAULT 0,
    total_cost NUMERIC(14,4) NOT NULL DEFAULT 0,
    UNIQUE (project_id, usage_date)
);

CREATE TABLE model_usage_monthly (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    month DATE NOT NULL,
    model_name TEXT NOT NULL,
    session_count INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER NOT NULL DEFAULT 0,
    total_cost NUMERIC(14,4) NOT NULL DEFAULT 0,
    UNIQUE (partner_id, month, model_name)
);

CREATE TABLE analytics_snapshots (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    snapshot_date DATE NOT NULL,
    metric_type TEXT NOT NULL,
    metric_value NUMERIC(18,4) NOT NULL,
    metadata JSONB,
    UNIQUE (partner_id, snapshot_date, metric_type)
);

CREATE TABLE provider_credentials (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    credential_label TEXT,
    api_key_encrypted TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_validated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (partner_id, provider)
);

CREATE TABLE model_catalog (
    id BIGSERIAL PRIMARY KEY,
    provider TEXT NOT NULL,
    model_name TEXT NOT NULL,
    modality TEXT NOT NULL DEFAULT 'chat',
    supports_parallel BOOLEAN NOT NULL DEFAULT FALSE,
    default_pricing JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (provider, model_name)
);

CREATE TABLE org_llm_settings (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    default_chat_model TEXT NOT NULL,
    enable_parallel_mode BOOLEAN NOT NULL DEFAULT FALSE,
    daily_message_limit INTEGER,
    token_alert_threshold INTEGER,
    provider_credential_id BIGINT REFERENCES provider_credentials(id) ON DELETE SET NULL,
    updated_by BIGINT REFERENCES partner_users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE prompt_templates (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT REFERENCES partners(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    scope TEXT NOT NULL DEFAULT 'partner',
    created_by BIGINT REFERENCES partner_users(id),
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE prompt_template_versions (
    id BIGSERIAL PRIMARY KEY,
    template_id BIGINT NOT NULL REFERENCES prompt_templates(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_by BIGINT REFERENCES partner_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (template_id, version)
);

CREATE TABLE prompt_bindings (
    id BIGSERIAL PRIMARY KEY,
    template_version_id BIGINT NOT NULL REFERENCES prompt_template_versions(id) ON DELETE CASCADE,
    scope_type TEXT NOT NULL CHECK (scope_type IN ('project', 'global')),
    scope_id BIGINT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    invoice_number TEXT NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    total_amount NUMERIC(14,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    issued_at TIMESTAMPTZ,
    due_date DATE,
    UNIQUE (partner_id, invoice_number)
);

CREATE TABLE invoice_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    project_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(14,2) NOT NULL DEFAULT 0,
    amount NUMERIC(14,2) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE payouts (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    payout_number TEXT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_amount NUMERIC(14,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    initiated_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    UNIQUE (partner_id, payout_number)
);

CREATE TABLE payout_items (
    id BIGSERIAL PRIMARY KEY,
    payout_id BIGINT NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,
    invoice_id BIGINT REFERENCES invoices(id) ON DELETE SET NULL,
    amount NUMERIC(14,2) NOT NULL,
    fee_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    net_amount NUMERIC(14,2) NOT NULL,
    notes TEXT
);

CREATE TABLE fee_rates (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    fee_type TEXT NOT NULL,
    percentage NUMERIC(5,2),
    flat_amount NUMERIC(14,2),
    effective_from DATE NOT NULL,
    effective_to DATE,
    UNIQUE (partner_id, fee_type, effective_from)
);

CREATE TABLE api_cost_daily (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    project_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
    usage_date DATE NOT NULL,
    provider TEXT NOT NULL,
    total_cost NUMERIC(14,4) NOT NULL,
    UNIQUE (partner_id, usage_date, provider, project_id)
);

CREATE TABLE project_finance_monthly (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    month DATE NOT NULL,
    contract_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    api_cost NUMERIC(14,2) NOT NULL DEFAULT 0,
    platform_fee NUMERIC(14,2) NOT NULL DEFAULT 0,
    payout_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    UNIQUE (project_id, month)
);

CREATE TABLE notification_preferences (
    id BIGSERIAL PRIMARY KEY,
    partner_user_id BIGINT NOT NULL REFERENCES partner_users(id) ON DELETE CASCADE,
    new_student_email BOOLEAN NOT NULL DEFAULT TRUE,
    project_deadline_email BOOLEAN NOT NULL DEFAULT TRUE,
    settlement_email BOOLEAN NOT NULL DEFAULT TRUE,
    api_cost_alert_email BOOLEAN NOT NULL DEFAULT TRUE,
    system_notice BOOLEAN NOT NULL DEFAULT TRUE,
    marketing_opt_in BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (partner_user_id)
);

CREATE TABLE email_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    partner_user_id BIGINT NOT NULL REFERENCES partner_users(id) ON DELETE CASCADE,
    subscription_type TEXT NOT NULL,
    is_subscribed BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (partner_user_id, subscription_type)
);

CREATE TABLE mfa_settings (
    partner_user_id BIGINT PRIMARY KEY REFERENCES partner_users(id) ON DELETE CASCADE,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    method TEXT,
    secret_encrypted TEXT,
    last_enabled_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE login_activity (
    id BIGSERIAL PRIMARY KEY,
    partner_user_id BIGINT REFERENCES partner_users(id) ON DELETE SET NULL,
    login_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    status TEXT NOT NULL DEFAULT 'success'
);

CREATE TABLE payout_accounts (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    account_number_encrypted TEXT NOT NULL,
    account_holder TEXT NOT NULL,
    routing_number TEXT,
    currency TEXT NOT NULL DEFAULT 'KRW',
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE business_profiles (
    partner_id BIGINT PRIMARY KEY REFERENCES partners(id) ON DELETE CASCADE,
    business_registration_number TEXT,
    company_name TEXT NOT NULL,
    representative_name TEXT NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT NOT NULL,
    tax_email TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_partner_primary_payout_account
    ON payout_accounts(partner_id)
    WHERE is_primary;
