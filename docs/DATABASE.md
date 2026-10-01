# NALVIUM — DATABASE

PostgreSQL. Schéma à implémenter via migrations versionnées.

## users
- id UUID
- email nullable
- phone nullable
- locale
- created_at
- deleted_at

Support d’un mode invité via installation/session avant création de compte.

## devices / guest_sessions
Identifiant pseudonyme pour continuité locale, sans fingerprinting invasif.

## diagnostic_sessions
- id
- user_id nullable
- guest_session_id nullable
- category
- subcategory
- status
- urgency
- risk_level
- diy_allowed
- created_at
- resolved_at

## diagnostic_messages
- id
- session_id
- role
- type
- content_json
- created_at

## diagnostic_media
- id
- session_id
- message_id nullable
- storage_key
- media_type
- consent_for_pro boolean
- created_at
- deleted_at

## repair_steps
- id
- session_id
- step_index
- instruction
- safety_note
- status
- created_at
- completed_at

## safety_events
- id
- session_id
- flag
- severity
- action_taken
- created_at

## leads
- id
- session_id
- user_id nullable
- first_name
- phone
- city
- postal_code
- desired_time_window
- trade
- summary
- urgency
- consent_at
- status
- created_at

## professionals
- id
- business_name
- legal_name nullable
- siren_siret nullable
- phone
- email
- verification_status
- active
- created_at

## professional_trades
- professional_id
- trade

## professional_zones
- professional_id
- postal_prefix / polygon / radius selon choix technique futur

## lead_assignments
- id
- lead_id
- professional_id
- status
- assigned_at
- viewed_at
- accepted_at

## feedback
- id
- session_id
- rating
- resolved boolean
- comment nullable
- created_at

## consent_events
Journal minimal :
- subject_id
- consent_type
- version
- granted/revoked
- timestamp

## analytics_events
Éviter les données sensibles dans payload.
- event_name
- anonymous/user id
- session_id nullable
- properties_json filtré
- created_at

## Rétention

Les durées exactes seront définies dans PRIVACY.md et la politique publique avant production. Prévoir suppression/anonymisation technique dès V1.
