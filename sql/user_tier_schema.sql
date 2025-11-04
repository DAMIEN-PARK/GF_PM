-- User tier schema for conceptual ERD
-- Target dialect: PostgreSQL 13+

CREATE EXTENSION IF NOT EXISTS citext;

-- 1. Accounts and profiles --------------------------------------------------

CREATE TABLE users (
    user_id            BIGSERIAL PRIMARY KEY,
    email              CITEXT NOT NULL UNIQUE,
    password_hash      TEXT NOT NULL,
    status             TEXT NOT NULL DEFAULT 'active', -- active, suspended, invited, deleted
    default_role       TEXT NOT NULL DEFAULT 'member',
    last_login_at      TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_profiles (
    user_id            BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    full_name          TEXT,
    job_title          TEXT,
    department         TEXT,
    phone_number       TEXT,
    location           TEXT,
    bio                TEXT,
    avatar_url         TEXT,
    avatar_initials    TEXT,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Personalization & preferences -----------------------------------------

CREATE TABLE user_preferences (
    user_id        BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    preferences    JSONB NOT NULL DEFAULT '{}'::JSONB,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_preference_history (
    history_id     BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    preferences    JSONB NOT NULL,
    changed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Notification settings --------------------------------------------------

CREATE TABLE user_notification_preferences (
    preference_id  BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    channel        TEXT NOT NULL, -- email, in_app, browser_push
    event_type     TEXT NOT NULL,
    is_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, channel, event_type)
);

CREATE TABLE notification_events (
    event_id       BIGSERIAL PRIMARY KEY,
    user_id        BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    channel        TEXT NOT NULL,
    event_type     TEXT NOT NULL,
    status         TEXT NOT NULL, -- queued, sent, failed
    payload        JSONB,
    delivered_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Security, sessions, privacy -------------------------------------------

CREATE TABLE user_security_settings (
    user_id                    BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    two_factor_enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    two_factor_method          TEXT,
    backup_codes               JSONB,
    last_password_change_at    TIMESTAMPTZ,
    recovery_email             CITEXT,
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_login_sessions (
    session_id     BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    device_name    TEXT,
    ip_address     INET,
    location       TEXT,
    user_agent     TEXT,
    logged_in_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    logged_out_at  TIMESTAMPTZ,
    is_current     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_privacy_settings (
    user_id                    BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    save_conversation_history  BOOLEAN NOT NULL DEFAULT TRUE,
    allow_data_collection      BOOLEAN NOT NULL DEFAULT TRUE,
    allow_personalized_ai      BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE account_deletion_requests (
    request_id     BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status         TEXT NOT NULL DEFAULT 'pending', -- pending, approved, completed, cancelled
    requested_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at   TIMESTAMPTZ,
    notes          TEXT
);

-- 5. Usage, history, analytics ---------------------------------------------

CREATE TABLE user_activity_events (
    event_id       BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    event_type     TEXT NOT NULL,
    related_type   TEXT,
    related_id     BIGINT,
    metadata       JSONB,
    occurred_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE usage_summaries (
    summary_id     BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    period_start   DATE NOT NULL,
    period_end     DATE NOT NULL,
    metric_type    TEXT NOT NULL,
    metric_value   NUMERIC NOT NULL,
    UNIQUE (user_id, period_start, metric_type)
);

CREATE TABLE model_usage_stats (
    stat_id            BIGSERIAL PRIMARY KEY,
    user_id            BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    model_name         TEXT NOT NULL,
    usage_count        INTEGER NOT NULL DEFAULT 0,
    total_tokens       BIGINT NOT NULL DEFAULT 0,
    avg_latency_ms     INTEGER,
    satisfaction_score NUMERIC(3,2),
    last_used_at       TIMESTAMPTZ,
    UNIQUE (user_id, model_name)
);

CREATE TABLE user_achievements (
    achievement_id BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    achievement_key TEXT NOT NULL,
    earned_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata       JSONB,
    UNIQUE (user_id, achievement_key)
);

-- 6. Projects & collaboration ----------------------------------------------

CREATE TABLE projects (
    project_id         BIGSERIAL PRIMARY KEY,
    owner_id           BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name               TEXT NOT NULL,
    description        TEXT,
    project_type       TEXT NOT NULL DEFAULT 'personal', -- personal, team
    status             TEXT NOT NULL DEFAULT 'active',
    progress_percent   NUMERIC(5,2) NOT NULL DEFAULT 0,
    practice_hours     NUMERIC(10,2) NOT NULL DEFAULT 0,
    conversation_count INTEGER NOT NULL DEFAULT 0,
    last_activity_at   TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_members (
    project_member_id  BIGSERIAL PRIMARY KEY,
    project_id         BIGINT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    user_id            BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role               TEXT NOT NULL DEFAULT 'member',
    status             TEXT NOT NULL DEFAULT 'active',
    invited_at         TIMESTAMPTZ,
    joined_at          TIMESTAMPTZ,
    UNIQUE (project_id, user_id)
);

CREATE TABLE project_tags (
    tag_id      BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    color       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_tag_assignments (
    assignment_id  BIGSERIAL PRIMARY KEY,
    project_id     BIGINT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    tag_id         BIGINT NOT NULL REFERENCES project_tags(tag_id) ON DELETE CASCADE,
    UNIQUE (project_id, tag_id)
);

CREATE TABLE project_metrics (
    metric_id       BIGSERIAL PRIMARY KEY,
    project_id      BIGINT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    metric_type     TEXT NOT NULL,
    metric_value    NUMERIC NOT NULL,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_activity (
    activity_id     BIGSERIAL PRIMARY KEY,
    project_id      BIGINT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    user_id         BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    activity_type   TEXT NOT NULL,
    details         JSONB,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. AI agents & practice sessions -----------------------------------------

CREATE TABLE ai_agents (
    agent_id        BIGSERIAL PRIMARY KEY,
    owner_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    role_description TEXT,
    status          TEXT NOT NULL DEFAULT 'draft', -- draft, active, archived
    icon            TEXT,
    template_source TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE agent_prompts (
    prompt_id       BIGSERIAL PRIMARY KEY,
    agent_id        BIGINT NOT NULL REFERENCES ai_agents(agent_id) ON DELETE CASCADE,
    version         INTEGER NOT NULL,
    system_prompt   TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (agent_id, version)
);

CREATE TABLE agent_examples (
    example_id      BIGSERIAL PRIMARY KEY,
    agent_id        BIGINT NOT NULL REFERENCES ai_agents(agent_id) ON DELETE CASCADE,
    example_type    TEXT NOT NULL DEFAULT 'few_shot',
    input_text      TEXT,
    output_text     TEXT,
    position        INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE agent_usage_stats (
    usage_stat_id   BIGSERIAL PRIMARY KEY,
    agent_id        BIGINT NOT NULL REFERENCES ai_agents(agent_id) ON DELETE CASCADE,
    usage_count     INTEGER NOT NULL DEFAULT 0,
    last_used_at    TIMESTAMPTZ,
    avg_rating      NUMERIC(3,2),
    total_tokens    BIGINT NOT NULL DEFAULT 0,
    UNIQUE (agent_id)
);

CREATE TABLE practice_sessions (
    session_id      BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title           TEXT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    notes           TEXT
);

CREATE TABLE practice_session_models (
    session_model_id    BIGSERIAL PRIMARY KEY,
    session_id          BIGINT NOT NULL REFERENCES practice_sessions(session_id) ON DELETE CASCADE,
    model_name          TEXT NOT NULL,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (session_id, model_name)
);

CREATE TABLE practice_responses (
    response_id     BIGSERIAL PRIMARY KEY,
    session_model_id BIGINT NOT NULL REFERENCES practice_session_models(session_model_id) ON DELETE CASCADE,
    prompt_text     TEXT NOT NULL,
    response_text   TEXT NOT NULL,
    token_usage     JSONB,
    latency_ms      INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE practice_ratings (
    rating_id       BIGSERIAL PRIMARY KEY,
    response_id     BIGINT NOT NULL REFERENCES practice_responses(response_id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    score           INTEGER NOT NULL,
    feedback        TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (response_id, user_id)
);

CREATE TABLE model_comparisons (
    comparison_id   BIGSERIAL PRIMARY KEY,
    session_id      BIGINT NOT NULL REFERENCES practice_sessions(session_id) ON DELETE CASCADE,
    model_a         TEXT NOT NULL,
    model_b         TEXT NOT NULL,
    winner_model    TEXT,
    latency_diff_ms INTEGER,
    token_diff      INTEGER,
    user_feedback   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Documents & knowledge base --------------------------------------------

CREATE TABLE documents (
    document_id     BIGSERIAL PRIMARY KEY,
    owner_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    file_format     TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    folder_path     TEXT,
    status          TEXT NOT NULL DEFAULT 'processing', -- processing, ready, failed
    chunk_count     INTEGER NOT NULL DEFAULT 0,
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE document_processing_jobs (
    job_id          BIGSERIAL PRIMARY KEY,
    document_id     BIGINT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    stage           TEXT NOT NULL, -- upload, parsing, embedding, indexing
    status          TEXT NOT NULL DEFAULT 'queued',
    message         TEXT,
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ
);

CREATE TABLE document_tags (
    tag_id      BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE
);

CREATE TABLE document_tag_assignments (
    assignment_id  BIGSERIAL PRIMARY KEY,
    document_id    BIGINT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    tag_id         BIGINT NOT NULL REFERENCES document_tags(tag_id) ON DELETE CASCADE,
    UNIQUE (document_id, tag_id)
);

CREATE TABLE document_usage (
    usage_id       BIGSERIAL PRIMARY KEY,
    document_id    BIGINT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    user_id        BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    usage_type     TEXT NOT NULL, -- retrieval, chat_reference, evaluation
    usage_count    INTEGER NOT NULL DEFAULT 0,
    last_used_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index recommendations -----------------------------------------------------

CREATE INDEX idx_user_activity_events_user_id ON user_activity_events (user_id, occurred_at DESC);
CREATE INDEX idx_usage_summaries_period ON usage_summaries (period_start, period_end);
CREATE INDEX idx_user_login_sessions_user ON user_login_sessions (user_id, logged_in_at DESC);
CREATE INDEX idx_project_members_user ON project_members (user_id);
CREATE INDEX idx_notification_events_user ON notification_events (user_id, created_at DESC);
CREATE INDEX idx_document_usage_document ON document_usage (document_id);

