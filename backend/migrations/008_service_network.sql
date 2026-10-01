CREATE TABLE IF NOT EXISTS service_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS service_offerings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES service_categories(id),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  short_description TEXT,
  long_description TEXT,
  active BOOLEAN NOT NULL DEFAULT FALSE,
  pricing_type TEXT NOT NULL CHECK (pricing_type IN ('FIXED','STARTING_FROM','RANGE','QUOTE_REQUIRED')),
  price_cents INTEGER,
  min_price_cents INTEGER,
  max_price_cents INTEGER,
  currency CHAR(3) NOT NULL DEFAULT 'EUR',
  callout_included TEXT,
  diagnosis_included TEXT,
  labor_description TEXT,
  parts_included TEXT,
  estimated_duration_minutes INTEGER,
  emergency_available BOOLEAN NOT NULL DEFAULT FALSE,
  evening_available BOOLEAN NOT NULL DEFAULT FALSE,
  weekend_available BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS service_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  postal_codes TEXT[] NOT NULL DEFAULT '{}',
  department_code TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS service_area_offerings (
  area_id UUID NOT NULL REFERENCES service_areas(id) ON DELETE CASCADE,
  offering_id UUID NOT NULL REFERENCES service_offerings(id) ON DELETE CASCADE,
  PRIMARY KEY (area_id, offering_id)
);

CREATE TABLE IF NOT EXISTS repair_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key TEXT,
  actor_key TEXT,
  session_id UUID REFERENCES diagnostic_sessions(id) ON DELETE SET NULL,
  equipment_id UUID REFERENCES equipments(id) ON DELETE SET NULL,
  service_offering_id UUID NOT NULL REFERENCES service_offerings(id),
  first_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  city TEXT,
  description TEXT NOT NULL,
  desired_time_window TEXT,
  source TEXT NOT NULL DEFAULT 'unknown',
  quoted_amount_cents INTEGER,
  quoted_currency CHAR(3),
  status TEXT NOT NULL DEFAULT 'REQUESTED',
  consent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (actor_key, idempotency_key)
);

CREATE TABLE IF NOT EXISTS repair_request_media (
  request_id UUID NOT NULL REFERENCES repair_requests(id) ON DELETE CASCADE,
  media_id UUID NOT NULL REFERENCES diagnostic_media(id) ON DELETE RESTRICT,
  PRIMARY KEY (request_id, media_id)
);

CREATE TABLE IF NOT EXISTS repair_request_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES repair_requests(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  from_status TEXT,
  to_status TEXT,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS professional_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES repair_requests(id) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES professionals(id),
  status TEXT NOT NULL DEFAULT 'assigned',
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (request_id)
);

CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES repair_requests(id) ON DELETE CASCADE,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coverage_interests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_key TEXT,
  postal_code TEXT NOT NULL,
  contact TEXT,
  consent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_usage_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,
  model TEXT,
  operation_type TEXT NOT NULL,
  input_tokens INTEGER,
  cached_tokens INTEGER,
  output_tokens INTEGER,
  image_count INTEGER NOT NULL DEFAULT 0,
  video_frame_count INTEGER NOT NULL DEFAULT 0,
  audio_duration_seconds INTEGER,
  estimated_cost_micros BIGINT,
  technical_reference TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS device_tokens (
  token TEXT PRIMARY KEY,
  actor_key TEXT,
  platform TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS service_offerings_active_idx ON service_offerings(active, display_order);
CREATE INDEX IF NOT EXISTS service_areas_postal_idx ON service_areas USING gin(postal_codes);
CREATE INDEX IF NOT EXISTS repair_requests_status_idx ON repair_requests(status, created_at DESC);
CREATE INDEX IF NOT EXISTS repair_request_events_request_idx ON repair_request_events(request_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_usage_created_idx ON ai_usage_events(created_at DESC);
