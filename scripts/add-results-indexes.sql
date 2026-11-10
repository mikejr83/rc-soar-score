-- One-time script for an existing PostgreSQL database (Neon), #843.
-- Indexes are only created together with their table, so a database created
-- before #843 lacks these. A fresh or reset database already has them.
-- Safe to run twice (IF NOT EXISTS) and while the API is running; no restart
-- is needed. Must match lib/schema/custom_indexes.dart in soar_score_data.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/add-results-indexes.sql

BEGIN;

CREATE INDEX IF NOT EXISTS rounds_contest ON rounds (contest_id);
CREATE INDEX IF NOT EXISTS matrix_assignments_scheduled_round ON matrix_assignments (scheduled_round_id);
CREATE INDEX IF NOT EXISTS score_placeholders_contest ON score_placeholders (contest_id);
CREATE INDEX IF NOT EXISTS score_placeholders_participation ON score_placeholders (contest_participation_id);
CREATE INDEX IF NOT EXISTS score_attempts_placeholder ON score_attempts (score_placeholder_id);
CREATE INDEX IF NOT EXISTS flight_results_contest_round ON flight_results (contest_id, credited_round_id);
CREATE INDEX IF NOT EXISTS participation_standings_contest_round ON participation_standings (contest_id, as_of_round);

COMMIT;
