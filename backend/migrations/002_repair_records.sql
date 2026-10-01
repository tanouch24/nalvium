CREATE TABLE IF NOT EXISTS repair_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES diagnostic_sessions(id) ON DELETE CASCADE,
    category text NOT NULL,
    title text NOT NULL,
    summary text NOT NULL DEFAULT '',
    before_media_id uuid REFERENCES diagnostic_media(id),
    after_media_id uuid REFERENCES diagnostic_media(id),
    started_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    status text NOT NULL DEFAULT 'in_progress',
    steps_completed jsonb NOT NULL DEFAULT '[]',
    professional_required boolean NOT NULL DEFAULT false,
    share_status text NOT NULL DEFAULT 'private'
);
CREATE TABLE IF NOT EXISTS shared_cases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    repair_record_id uuid NOT NULL REFERENCES repair_records(id) ON DELETE CASCADE,
    category text NOT NULL,
    subcategory text NOT NULL DEFAULT '',
    problem_summary text NOT NULL,
    solution_summary text NOT NULL DEFAULT '',
    before_media_public_reference text,
    after_media_public_reference text,
    created_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz
);
CREATE INDEX IF NOT EXISTS idx_repair_records_session ON repair_records(session_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_repair_records_category ON repair_records(category, status);
CREATE INDEX IF NOT EXISTS idx_shared_cases_category ON shared_cases(category, created_at DESC) WHERE revoked_at IS NULL;
