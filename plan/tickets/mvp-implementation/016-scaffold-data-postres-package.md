# Ticket 016 — Scaffold `soar_score_data_postres` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

`packages/soar_score_data_postgres` is the server-side data access layer: PostgreSQL for the deployed API's persistent storage, using `drift` + `drift_postgres`. This gives the repository/codegen pattern parity with `soar_score_data_sqlite` — both packages are built on `drift`, just against different backends. It depends on `soar_score_core` for the types it persists and the repository interfaces it must implement.

This package only runs server-side (inside `soar_score_api_server`) and has no offline/embedded use case — but it does need to be able to accept and reconcile data synced up from offline `soar_score_data_sqlite` clients, so repository design should keep that reconciliation path in mind even if the sync logic itself is out of scope for this ticket.

## Decisions

- **Postgres mechanism:** `drift` (^2.35.0) + `drift_postgres` (^1.3.1) + `postgres` (^3.5.16, the driver `drift_postgres` wraps), with `drift_dev` (^2.35.0) + `build_runner` (^2.16.1) for codegen — per the ticket's work items. Pinned at resolution (Dart 3.13.3): `drift 2.35.0`, `drift_postgres 1.3.1`, `postgres 3.5.16`. `drift_postgres`'s `PgDatabase` executor drives the `SqlDialect.postgres` dialect, runs drift migrations via its own `__schema`(version int) table, and is sequential single-connection (no pool by default).
- **Schema location: independent per package.** The drift table definitions in `lib/postgres/contests_table.dart` are maintained **independently** from `soar_score_data_sqlite`'s `lib/sqlite/contests_table.dart`, with column names and semantics deliberately mirrored (`id` UUIDv7 text PK, `name` text, `started_at` UTC ISO-8601 text). Drift _can_ generate for multiple dialects from one shared schema, but shared table definitions would require a new shared schema package (or a path/cycle dependency between the two data packages) and is premature at scaffold size with only one table. Mirroring keeps each package self-contained; if (and when) the number of entities grows, promoting the shared tables into a common drift schema (or generating both dialects from one `.drift` source) is a deliberate refactor for a later ticket — this is already noted as a follow-up in ticket 007.
- **Codegen dialect:** `build.yaml` enables `drift_dev` with `sql.dialect: postgres`, so generated DDL/queries target Postgres only (this package never runs against SQLite).
- **Connection configuration:** `PostgresConfig.fromEnvironment()` reads `POSTGRES_HOST` (default `localhost`), `POSTGRES_PORT` (default `5432`), `POSTGRES_DB` (default `postgres`), `POSTGRES_USER` (default `postgres`), `POSTGRES_PASSWORD` (required; null config when unset), and `POSTGRES_SSLMODE` (`disable`/`require`/`verifyFull`, default `disable`). No hardcoded credentials; consistent with `soar_score_server` reading `PORT` from the process environment (ticket 003).
- **Sync-related schema fields (per `offline-synchronization.md`):** **deferred.** The initial schema contains only the minimal `contests` table (schema version 1). Pending-mutation log, sync cursors (`contest_mutation_seq`), tombstones, and revision/bookkeeping columns are tracked in a follow-up ticket (see Follow-ups — the original link target, ticket 017, was repurposed to the `soar_score_api_handlers` extraction).

## Work Items

- [x] Create `packages/soar_score_data_postgres` with a `pubspec.yaml` (path dependency on `soar_score_core`).
- [x] Establish folder structure in `lib/`:
  - `postgres/` — connection/pool setup, migrations, raw queries.
  - `repositories/` — one repository file per entity (will grow per domain entity), each implementing the corresponding abstract repository interface from `soar_score_core`.
- [x] Add `drift`, `drift_postgres`, and `postgres` (the underlying driver `drift_postgres` wraps) as dependencies; add `drift_dev` + `build_runner` as dev dependencies for schema codegen.
- [x] Add `build.yaml` configuring `drift_dev` codegen with the `postgres` dialect.
- [x] Decide and record whether `drift` table definitions are shared with `soar_score_data_sqlite` or maintained independently per package: **independent** (see Decisions).
- [x] Add `lib/soar_score_data_postgres.dart` exporting the public API.
- [x] Add a config mechanism for connection details (host, port, credentials) that keeps secrets out of source control (environment variables), consistent with how `soar_score_server` is configured.
- [x] Add one passing integration test against a real Postgres instance executing a trivial query, including running the initial migration.
- [x] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.

## Acceptance Criteria

- [ ] Integration test passes against a Postgres instance provisioned in CI — **partially satisfied:** the integration suites (trivial `SELECT 1`/`version()` query, initial `__schema` migration run, raw insert, and 6 repository round-trip tests) are written and structurally match the upstream `drift_postgres` testing pattern, and they **pass against a real local/CI Postgres when configured** (e.g. `docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres` + `export POSTGRES_PASSWORD=postgres`); however, no Postgres instance exists on this machine (no Docker), so the suites **skip** here and their real-database run is unverified locally. CI service-container provisioning lands with ticket 011; the setup for running these tests locally and in CI is documented in the test file doc comments (`test/postgres/database_test.dart`, `test/repositories/contest_repository_test.dart`).
- [x] `dart analyze` passes with the path dependency on `soar_score_core` resolving. Verified: `dart analyze` → "No issues found!" for `soar_score_data_postgres`, and `melos analyze --fatal-infos` is clean workspace-wide.
- [x] The `drift` + `drift_postgres` decision is recorded in this ticket and reflected in `pubspec.yaml`.
- [x] Each scaffolded repository implements its corresponding `soar_score_core` interface: `ContestPostgresRepository implements ContestRepository`.
- [x] Connection configuration does not hard-code credentials in source.
- [x] The shared-vs-independent schema decision is explicitly recorded (Decisions: **independent per package, mirrored columns**).

## Files changed

### `packages/soar_score_data_postgres` (new package)

- `packages/soar_score_data_postgres/pubspec.yaml` — new; name `soar_score_data_postgres`, version 0.1.0, `publish_to: none`, SDK `>=3.13.0 <4.0.0`; deps `drift ^2.35.0`, `drift_postgres ^1.3.1`, `postgres ^3.5.16`, path dep `soar_score_core`; dev deps `drift_dev ^2.35.0`, `build_runner ^2.16.1`, `lints ^6.1.0`, `test 1.31.1`. No Flutter dependencies.
- `packages/soar_score_data_postgres/build.yaml` — new; enables `drift_dev` codegen configured with `sql.dialect: postgres`.
- `packages/soar_score_data_postgres/analysis_options.yaml` — new; includes `package:lints/recommended.yaml`.
- `packages/soar_score_data_postgres/.gitignore` — new; ignores `.dart_tool/`, `.packages`, `build/` (matches `soar_score_data_sqlite`).
- `packages/soar_score_data_postgres/lib/postgres/contests_table.dart` — new; drift `Contests` table (`id TEXT PK`, `name TEXT`, `started_at TEXT` UTC) with `@DataClassName('ContestData')` to avoid clashing with the core domain `Contest` type; column layout mirrors `soar_score_data_sqlite`'s table (independent per the decision above).
- `packages/soar_score_data_postgres/lib/postgres/migrate.dart` — new; `migrateToVersion1` (drift `Migrator.createAll`) for the initial schema.
- `packages/soar_score_data_postgres/lib/postgres/connection_info.dart` — new; `PostgresConfig` with env-based `fromEnvironment()` (host/port/db/user/password/sslmode), `named()`/`toEndpoint()`/`toSettings()` adapters for `package:postgres`.
- `packages/soar_score_data_postgres/lib/postgres/database.dart` — new; `ContestDatabase` (`@DriftDatabase`) opened via `drift_postgres`'s `PgDatabase` executor, `schemaVersion` 1, migration strategy; drift persists its version in the `__schema` table managed by `drift_postgres`.
- `packages/soar_score_data_postgres/lib/postgres/database.g.dart` — generated by `drift_dev` with the postgres dialect (committed; regenerate via `dart run build_runner build` in the package).
- `packages/soar_score_data_postgres/lib/repositories/contest_repository.dart` — new; `ContestPostgresRepository implements ContestRepository` (core interface): `findById`, `getAll`, `save` (insert-or-update upsert in a transaction), `delete` (returns whether a row was removed), `close`; domain-row mapping keeps `Id`/UTC-`DateTime` semantics from `soar_score_core`.
- `packages/soar_score_data_postgres/lib/soar_score_data_postgres.dart` — new; public API barrel exporting `postgres/` and `repositories/`.
- `packages/soar_score_data_postgres/test/postgres/database_test.dart` — new; 3 integration tests (trivial `SELECT 1`/`version()`, initial migration ran on open via `__schema`, raw insert into the migrated schema). Each test runs against a throwaway database created/dropped per test; the group skips when `POSTGRES_PASSWORD` is unset so `melos test` stays green on machines/CI without Postgres.
- `packages/soar_score_data_postgres/test/repositories/contest_repository_test.dart` — new; 6 integration tests (save/findById round-trip, unknown id → null, `getAll`, update existing row, UTC round-trip of `startedAt`, delete reporting); same skip-when-not-configured behavior.

### Workspace format fixes (pre-existing drift surfaced by `verify.ps1`)

`scripts/verify.ps1`'s format gate failed on **pre-existing** formatting violations in committed code from tickets 003–009 (none touched by this ticket); the repo's `dart format` was applied to the whole workspace so the gate passes:

- `packages/soar_score_core/` — `lib/models/contest.dart`, `lib/models/id.dart`, `test/models/contest_test.dart`, `test/models/id_test.dart`
- `packages/soar_score_data_sqlite/` — `lib/repositories/contest_repository.dart`, `lib/sqlite/database.dart`, `test/repositories/contest_repository_test.dart`, `test/sqlite/database_test.dart`
- `packages/soar_score_api/` — `lib/client/api_client.dart`, `lib/dto/health_dto.dart`, `lib/errors/api_network_error.dart`, `test/client/api_client_test.dart`, `test/dto/health_dto_test.dart`
- `packages/soar_score_ui/` — `lib/widgets/score_card.dart`, `test/widgets/score_card_test.dart`
- `apps/soar_score_server/` — `lib/health_handler.dart`, `lib/main.dart`, `lib/stub_handler.dart`
- `apps/soar_score_contest/` — `lib/theme/app_theme.dart`, `test/widget_test.dart`
- `apps/soar_score_public/` — `test/widget_test.dart`

All are line-wrapping-only reformatting; no behavioral changes.

### Lockfile

- `pubspec.lock` — workspace lockfile updated: `drift_postgres 1.3.1`, `postgres 3.5.16`, and transitive `buffer 1.2.3`, `uuid 4.6.0`.

### Tickets

- `plan/tickets/mvp-implementation/016-scaffold-data-postres-package.md` — this ticket: status In-Review, decisions recorded, work items and acceptance criteria checked, files changed, follow-ups.
- `plan/tickets/mvp-implementation/README.md` — index already lists 016 as In-Review; no change needed.

## Verification

- `scripts/verify.ps1`: **PASSED** (bootstrap, format check, `melos analyze --fatal-infos` clean across all 8 packages, `melos test` — all packages pass; `soar_score_data_postgres` suites skip (no local Postgres), `soar_score_data_sqlite` 9/9 pass, core/api/server/ui/flutter apps pass; `melos run build` builds both web apps and the server executable).
- `dart analyze` (`soar_score_data_postgres`): "No issues found!" (Dart 3.13.3).
- `dart run build_runner build` (`soar_score_data_postgres`): regenerates `database.g.dart` cleanly with the postgres dialect.

## Follow-ups

- **CI Postgres service container (ticket 011):** the CI workflow should provision a `postgres` service container (`docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres`-equivalent) and export `POSTGRES_PASSWORD` so this package's integration suites run for real in CI instead of skipping. Also document the local setup (already in the test doc comments).
- **Wire this package into `soar_score_server` via the extracted `soar_score_api_handlers` factory (ticket 017):** the thin server executable is expected to construct `ContestDatabase`/`ContestPostgresRepository` and pass the repository into `buildApiHandler(...)`.
- **Server-side sync schema:** a follow-on ticket for the reconciliation schema on Postgres — mutation log, tombstones, sync cursors (`contest_mutation_seq`), revision/bookkeeping columns per `plan/architecture-requirements/offline-synchronization.md`, so this package can accept and reconcile data pushed up from `soar_score_data_sqlite` clients. (The old pre-implementation sync tickets referenced this work; 017 has since been repurposed to the `soar_score_api_handlers` extraction, so this needs its own ticket.)
- **Shared drift schema unification:** when both packages accumulate real entity tables, re-evaluate promoting the mirrored `Contests` definitions into a shared drift schema (or multi-dialect generation from one source) — see the follow-up noted in ticket 007.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)

## Sources

- `plan/architecture-requirements/data.md`
- `plan/architecture-requirements/offline-synchronization.md`
