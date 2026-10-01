CREATE TABLE IF NOT EXISTS assistant_threads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    context_type text,
    context_id text,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS assistant_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id uuid NOT NULL REFERENCES assistant_threads(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content text NOT NULL DEFAULT '',
    media_references uuid[] NOT NULL DEFAULT '{}',
    context_json jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_assistant_messages_thread ON assistant_messages(thread_id, created_at);
