ALTER TABLE diagnostic_sessions ADD COLUMN IF NOT EXISTS actor_key TEXT;

CREATE TABLE IF NOT EXISTS community_profiles (
  actor_key TEXT PRIMARY KEY,
  handle TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_key TEXT NOT NULL REFERENCES community_profiles(actor_key),
  repair_record_id UUID REFERENCES repair_records(id) ON DELETE SET NULL,
  equipment_id UUID REFERENCES equipments(id) ON DELETE SET NULL,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 160),
  category TEXT NOT NULL DEFAULT 'other',
  subcategory TEXT,
  equipment_type TEXT,
  brand TEXT,
  model TEXT,
  problem_summary TEXT NOT NULL CHECK (char_length(problem_summary) BETWEEN 1 AND 2000),
  solution_summary TEXT NOT NULL CHECK (char_length(solution_summary) BETWEEN 1 AND 3000),
  materials_used TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  moderation_status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS community_post_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  source_media_id UUID REFERENCES diagnostic_media(id) ON DELETE SET NULL,
  public_media_id UUID NOT NULL,
  media_kind TEXT NOT NULL CHECK (media_kind IN ('before', 'after', 'additional')),
  storage_key TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  actor_key TEXT NOT NULL REFERENCES community_profiles(actor_key),
  parent_comment_id UUID REFERENCES community_comments(id) ON DELETE SET NULL,
  content TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1200),
  moderation_status TEXT NOT NULL DEFAULT 'approved',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_reactions (
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  actor_key TEXT NOT NULL REFERENCES community_profiles(actor_key),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, actor_key)
);

CREATE TABLE IF NOT EXISTS community_saved_posts (
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  actor_key TEXT NOT NULL REFERENCES community_profiles(actor_key),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, actor_key)
);

CREATE TABLE IF NOT EXISTS community_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'comment')),
  target_id UUID NOT NULL,
  actor_key TEXT NOT NULL REFERENCES community_profiles(actor_key),
  reason TEXT NOT NULL,
  note TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS community_posts_feed_idx ON community_posts(status, moderation_status, published_at DESC);
CREATE INDEX IF NOT EXISTS community_posts_search_idx ON community_posts USING gin (to_tsvector('simple', title || ' ' || problem_summary || ' ' || solution_summary));
CREATE INDEX IF NOT EXISTS community_comments_post_idx ON community_comments(post_id, created_at);
