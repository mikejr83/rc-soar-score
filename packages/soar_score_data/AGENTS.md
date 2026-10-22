# Data Package Agent Guide

Drift database schema and the repository implementations for both SQLite (native app) and PostgreSQL (server). Pure Dart.

## Structure

- `lib/database.dart` — `SoarScoreDatabase` (Drift); `database.g.dart` is generated and checked in
- `lib/schema/` — table definitions (`tables/`), table groups, `DatabaseProfile` (native or server), enum values, custom indexes
- `lib/repositories/` — one Drift implementation per contract in `soar_score_core`; `repository.dart` assembles them
- `lib/sync/` — `SyncStore`, change applier, unit of work and entity stores (hand-written SQL goes through the placeholder rewrite helper)
- `lib/seeding/` — system data seeder and the demo database seeder (`seeding/demo/`)
- `lib/import/` — GliderScore import process runner
- `lib/exchange/` — contest export and import (`.rcsoar` files, see `plan/architecture-requirements/offline-synchronization.md`). A new table must be classified in `exchange_tables.dart` (exported, derived, system, installation state or service only); a test fails otherwise. An account column in an exported table must be listed in `localAccountReferences`.
- `test/` — mirrors `lib/`; `test/support/` holds the shared database setup

## Boundaries

- **Pure Dart, no Flutter.** Depends on `soar_score_core`, `drift`, `drift_postgres`, `postgres`, `sqlite3` and `logging`. Must not depend on `soar_score_api`, `soar_score_api_handlers`, `soar_score_sync` or any app.
- Repositories are contracts in `soar_score_core`; this package only implements them. Add or change the contract in core first.
- **No business logic.** Persistence, mapping and constraints only. Scoring, ranking and rules belong in `soar_score_core`.
- One table per entity, with UTC ISO timestamps. Fields trace to `plan/data-model/entities/`.
- Schema changes stay in schema version 1, edited in place. A stale local `soar_score.db` must be deleted afterwards.
- Keep SQL working on both backends. `build.yaml` generates SQL for both dialects; do not add SQLite-only or PostgreSQL-only SQL.

## Generated Code

- After any table change, regenerate: `dart run build_runner build --delete-conflicting-outputs` (from this directory) and commit `database.g.dart`.

## Demo Data

- A new model, repository or service the demo can use updates the demo seeder, or the repository is exempted in `test/seeding/demo_coverage_test.dart` (see the root file).

## Testing

- Run: `dart test`
- Repository and schema tests run on SQLite and PostgreSQL. PostgreSQL runs through `scripts/test-postgres.ps1` (or `scripts/test-postgres.sh`), which starts a local server.
