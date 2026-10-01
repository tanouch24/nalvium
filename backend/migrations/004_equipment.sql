CREATE TABLE IF NOT EXISTS equipments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category text NOT NULL,
    subcategory text,
    display_name text NOT NULL,
    brand text,
    model text,
    serial_number text,
    room text,
    notes text,
    primary_media_id uuid REFERENCES diagnostic_media(id),
    identification_confidence numeric CHECK (identification_confidence IS NULL OR (identification_confidence >= 0 AND identification_confidence <= 1)),
    identification_source text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz
);
CREATE TABLE IF NOT EXISTS equipment_media (
    equipment_id uuid NOT NULL REFERENCES equipments(id) ON DELETE CASCADE,
    media_id uuid NOT NULL REFERENCES diagnostic_media(id) ON DELETE CASCADE,
    media_type text NOT NULL CHECK (media_type IN ('primary', 'nameplate', 'other')),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (equipment_id, media_id)
);
ALTER TABLE diagnostic_sessions ADD COLUMN IF NOT EXISTS equipment_id uuid REFERENCES equipments(id);
ALTER TABLE repair_records ADD COLUMN IF NOT EXISTS equipment_id uuid REFERENCES equipments(id);
ALTER TABLE assistant_threads ADD COLUMN IF NOT EXISTS equipment_id uuid REFERENCES equipments(id);
CREATE INDEX IF NOT EXISTS idx_equipments_room ON equipments(room) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_equipment_media_equipment ON equipment_media(equipment_id, created_at);
CREATE INDEX IF NOT EXISTS idx_diagnostic_sessions_equipment ON diagnostic_sessions(equipment_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_repair_records_equipment ON repair_records(equipment_id, started_at DESC);
