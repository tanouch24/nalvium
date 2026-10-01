ALTER TABLE diagnostic_sessions ADD COLUMN IF NOT EXISTS assistant_thread_id UUID REFERENCES assistant_threads(id) ON DELETE SET NULL;
ALTER TABLE diagnostic_media ADD COLUMN IF NOT EXISTS byte_size BIGINT;
ALTER TABLE diagnostic_media ADD COLUMN IF NOT EXISTS duration_ms INTEGER;
ALTER TABLE diagnostic_media ADD COLUMN IF NOT EXISTS width INTEGER;
ALTER TABLE diagnostic_media ADD COLUMN IF NOT EXISTS height INTEGER;

CREATE TABLE IF NOT EXISTS repair_verifications (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES diagnostic_sessions(id) ON DELETE CASCADE,
  before_media_id UUID REFERENCES diagnostic_media(id) ON DELETE SET NULL,
  after_media_id UUID REFERENCES diagnostic_media(id) ON DELETE SET NULL,
  status TEXT NOT NULL,
  observations JSONB NOT NULL DEFAULT '[]'::jsonb,
  remaining_issue TEXT,
  risk_level TEXT,
  next_action JSONB,
  requires_professional BOOLEAN NOT NULL DEFAULT FALSE,
  request_another_photo BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS professional_case_dossiers (
  id UUID PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES diagnostic_sessions(id) ON DELETE CASCADE,
  equipment_id UUID REFERENCES equipments(id) ON DELETE SET NULL,
  dossier_json JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'ready',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS repair_verifications_session_idx ON repair_verifications(session_id, created_at DESC);
