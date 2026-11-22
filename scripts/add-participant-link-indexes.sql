-- One-time script for an existing PostgreSQL database (Neon), #545.
-- Indexes are only created together with their table, so a database created
-- before #545 lacks these. A fresh or reset database already has them.
-- Safe to run twice (IF NOT EXISTS) and while the API is running; no restart
-- is needed. Must match lib/schema/custom_indexes.dart in soar_score_data.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/add-participant-link-indexes.sql

BEGIN;

CREATE INDEX IF NOT EXISTS participant_account_links_account ON participant_account_links (account_id);
CREATE INDEX IF NOT EXISTS participant_profiles_lower_email ON participant_profiles (lower(email));

COMMIT;
