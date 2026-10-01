ALTER TABLE equipments ADD COLUMN IF NOT EXISTS purchase_date date;
ALTER TABLE equipments ADD COLUMN IF NOT EXISTS purchase_price numeric;
ALTER TABLE equipments ADD COLUMN IF NOT EXISTS purchase_currency varchar(3);
ALTER TABLE equipments ADD COLUMN IF NOT EXISTS seller text;

CREATE TABLE IF NOT EXISTS equipment_documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id uuid NOT NULL REFERENCES equipments(id) ON DELETE CASCADE,
    media_id uuid NOT NULL REFERENCES diagnostic_media(id) ON DELETE RESTRICT,
    document_type text NOT NULL DEFAULT 'other',
    display_name text NOT NULL,
    mime_type text NOT NULL,
    original_filename text,
    document_date date,
    extracted_text text,
    extraction_status text NOT NULL DEFAULT 'pending',
    extraction_json jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS equipment_document_chunks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid NOT NULL REFERENCES equipment_documents(id) ON DELETE CASCADE,
    chunk_index int NOT NULL,
    text text NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(document_id, chunk_index)
);
CREATE TABLE IF NOT EXISTS equipment_warranties (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id uuid NOT NULL REFERENCES equipments(id) ON DELETE CASCADE,
    source_document_id uuid REFERENCES equipment_documents(id) ON DELETE SET NULL,
    provider text,
    start_date date,
    end_date date,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS equipment_maintenance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id uuid NOT NULL REFERENCES equipments(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    maintenance_type text NOT NULL DEFAULT 'other',
    performed_at date,
    next_due_at date,
    status text NOT NULL DEFAULT 'completed',
    source text NOT NULL DEFAULT 'user',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_equipment_documents_equipment ON equipment_documents(equipment_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_equipment_document_chunks_document ON equipment_document_chunks(document_id, chunk_index);
CREATE INDEX IF NOT EXISTS idx_equipment_maintenance_due ON equipment_maintenance(equipment_id, next_due_at);
