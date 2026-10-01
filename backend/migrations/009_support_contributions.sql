CREATE TABLE IF NOT EXISTS support_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_key TEXT,
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
  currency CHAR(3) NOT NULL DEFAULT 'EUR',
  provider TEXT NOT NULL,
  provider_transaction_reference TEXT,
  status TEXT NOT NULL CHECK (status IN ('UNAVAILABLE','READY','PROCESSING','SUCCESS','CANCELLED','FAILED')),
  source TEXT NOT NULL CHECK (source IN ('RESOLUTION_SCREEN','SETTINGS')),
  repair_session_id UUID REFERENCES diagnostic_sessions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  confirmed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS support_contributions_created_idx ON support_contributions(created_at DESC);

CREATE TABLE IF NOT EXISTS commerce_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL CHECK (event_name IN ('required_items_shown', 'item_owned', 'nearby_store_clicked', 'online_purchase_clicked', 'repair_resumed_after_material')),
  item_type TEXT NOT NULL CHECK (item_type IN ('TOOL', 'PART', 'CONSUMABLE', 'SAFETY_EQUIPMENT')),
  normalized_item TEXT NOT NULL,
  provider TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS commerce_events_created_idx ON commerce_events(created_at DESC);
