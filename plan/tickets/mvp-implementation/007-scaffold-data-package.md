# Ticket 007 — Scaffold `soar_score_data_sqlite` Package

> **Note:** `soar_score_data_sqlite` and its sibling package were later unified into `packages/soar_score_data` (one Drift schema opened over SQLite or PostgreSQL). The package name below is historical.

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

`packages/soar_score_data_sqlite` is the data access layer: SQLite for local/offline storage. It will hold repositories and SQLite migration code. This ticket creates the package skeleton with the folder structure and an in-memory example repository so the repository pattern exists before real repositories are written. It depends on `soar_score_core` for the types it persists and the repository interfaces it must implement.

This package must remain **pure Dart** (no Flutter dependency): it is consumed both by the Windows-embedded API server and, indirectly, by any future non-Flutter tooling. Flutter-only SQLite packages (e.g. `sqlite3_flutter_libs`) are out of scope here.

## Decisions

- **SQLite mechanism:** `drift` (+ `drift_dev`/`build_runner` codegen) on top of `sqlite3` (Dart `dart:ffi` bindings, not `sqlite3_flutter_libs`), per the ticket's work items. Pinned at resolution time: `drift 2.35.0`, `sqlite3 3.6.0` (Dart 3.13.3). Noted: drift 2.x dropped sqflite-style naming — generated row classes and `Migrator` naming differ from 1.x docs.
- **Sync-related schema fields (per `offline-synchronization.md`):** **deferred.** The initial schema contains only the minimal `contests` table (schema version 1). Pending-mutation log, sync cursors (`contest_mutation_seq`), tombstones, and revision/bookkeeping columns are tracked in [017-sqlite-sync-schema.md](017-sqlite-sync-schema.md).
- **Repository interface gap:** `soar_score_core` (ticket 006, In-Review) contained no repository interface. An abstract `ContestRepository` was added to `packages/soar_score_core/lib/repositories/` and exported from the core barrel, so the scaffolded repository implements a core-owned contract as required.

## Work Items

- [x] Create `packages/soar_score_data_sqlite` with a `pubspec.yaml` (path dependency on `soar_score_core`).
- [x] Establish folder structure in `lib/`:
  - `sqlite/` — database open, migrations, raw queries.
  - `repositories/` — one repository file per entity (will grow per domain entity), each implementing the corresponding abstract repository interface from `soar_score_core`.
- [x] Add `drift` + `sqlite3` (Dart `dart:ffi` bindings, not `sqlite3_flutter_libs`) as dependencies; add `drift_dev` + `build_runner` as dev dependencies for schema codegen.
- [x] Add `build.yaml` configuring `drift_dev` codegen for this package.
- [x] Add `lib/soar_score_data_sqlite.dart` exporting the public API.
- [x] Add one passing unit test against an in-memory database (`NativeDatabase.memory()`) executing a trivial query, including running the initial schema migration.
- [x] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.
- [x] Record whether sync-related schema fields are included or deferred: **deferred** to [017-sqlite-sync-schema.md](017-sqlite-sync-schema.md) (see Decisions).

## Acceptance Criteria

- [x] In-memory database test passes without requiring the Flutter SQLite plugin in CI (a native `libsqlite3` via `dart:ffi` is expected to be present, as is standard on CI Linux images). Verified locally on Windows: the `sqlite3` package's build hooks resolve and load a prebuilt `sqlite3.dll` for the platform, so `dart test` passes on this machine without any bundled binary; the test itself is platform-neutral and will run on CI Linux images unchanged.
- [x] `dart analyze` passes with the path dependency on `soar_score_core` resolving. Verified: `dart analyze` → "No issues found!" in both `soar_score_core` and `soar_score_data_sqlite` (Dart 3.13.3).
- [x] The SQLite mechanism decision (`drift` + `sqlite3`) is recorded in this ticket and reflected in `pubspec.yaml`.
- [x] Each scaffolded repository implements its corresponding `soar_score_core` interface: `ContestSqliteRepository implements ContestRepository`.
- [x] The sync-fields decision is explicitly resolved: deferred, with linked follow-on ticket 017.

## Files changed

### `packages/soar_score_data_sqlite` (new package)

- `packages/soar_score_data_sqlite/pubspec.yaml` — new; name `soar_score_data_sqlite`, version 0.1.0, `publish_to: none`, SDK `>=3.13.0 <4.0.0`; deps `drift ^2.35.0`, `sqlite3 ^3.6.0`, path dep `soar_score_core`; dev deps `drift_dev ^2.35.0`, `build_runner ^2.16.1`, `lints ^6.1.0`, `test ^1.32.0`. No Flutter dependencies.
- `packages/soar_score_data_sqlite/build.yaml` — new; enables `drift_dev` codegen for the package; codegen runs via `dart run build_runner build`.
- `packages/soar_score_data_sqlite/analysis_options.yaml` — new; includes `package:lints/recommended.yaml`.
- `packages/soar_score_data_sqlite/.gitignore` — new; ignores `.dart_tool/`, `.packages`, `build/` (matches `soar_score_core`).
- `packages/soar_score_data_sqlite/lib/sqlite/contests_table.dart` — new; drift `Contests` table (`id TEXT PK`, `name TEXT`, `started_at TEXT` UTC) with `@DataClassName('ContestData')` to avoid clashing with the core domain `Contest` type.
- `packages/soar_score_data_sqlite/lib/sqlite/migrate.dart` — new; `migrateToVersion1` (drift `Migrator.createAll`) for the initial schema.
- `packages/soar_score_data_sqlite/lib/sqlite/database.dart` — new; `ContestDatabase` (`@DriftDatabase`) with `open(path)` / `inMemory()` (`NativeDatabase.memory()`), `schemaVersion` 1, migration strategy, raw-query support via drift's `customSelect`/`customInsert`.
- `packages/soar_score_data_sqlite/lib/sqlite/database.g.dart` — generated by `drift_dev` (committed; regenerate after schema changes).
- `packages/soar_score_data_sqlite/lib/repositories/contest_repository.dart` — new; `ContestSqliteRepository implements ContestRepository` (core interface): `findById`, `getAll`, `save` (insert-or-update upsert in a transaction), `delete` (returns whether a row was removed), `close`; domain-row mapping keeps `Id`/UTC-`DateTime` semantics from `soar_score_core`.
- `packages/soar_score_data_sqlite/lib/soar_score_data_sqlite.dart` — new; public API barrel exporting `repositories/` and `sqlite/` (the only import required by consumers).
- `packages/soar_score_data_sqlite/test/sqlite/database_test.dart` — new; 3 tests: trivial `SELECT 1` query without the Flutter SQLite plugin, initial schema migration ran on open (user_version 1, `contests` table present), raw insert into the migrated schema.
- `packages/soar_score_data_sqlite/test/repositories/contest_repository_test.dart` — new; 6 tests: save/findById round-trip, unknown id → null, `getAll`, update existing row, UTC round-trip of `startedAt`, delete reporting.

### `packages/soar_score_core` (repository interface added for 007)

- `packages/soar_score_core/lib/repositories/contest_repository.dart` — new; abstract `ContestRepository` (findById/getAll/save/delete/close over `Contest` + `Id`), pure Dart, no new dependencies. Fills the interface gap required by this ticket (see Decisions).
- `packages/soar_score_core/lib/soar_score_core.dart` — exports the new `repositories/contest_repository.dart`.

### Tickets

- `plan/tickets/mvp-implementation/017-sqlite-sync-schema.md` — new follow-on ticket for the sync-related schema (mutation log, cursors, tombstones, bookkeeping columns), linked from this ticket's decision.
- `plan/tickets/mvp-implementation/007-scaffold-data-package.md` — this ticket: status In-Review, decisions recorded, work items and acceptance criteria checked, files changed.
- `plan/tickets/mvp-implementation/README.md` — index: 007 → In-Review, 017 added.

## Verification

- `dart analyze` (both packages): "No issues found!" (Dart 3.13.3).
- `dart test` (`soar_score_data_sqlite`): 9/9 passing.
- `dart test` (`soar_score_core`): 12/12 passing (unchanged from ticket 006).

## Follow-ups

- Sync-related local schema (client mutation log, sync cursors, tombstones, revision/bookkeeping columns) — [017-sqlite-sync-schema.md](017-sqlite-sync-schema.md).
- Real per-entity repositories as domain entities are modeled in `soar_score_core` (one repository file per entity).
- Shared drift schema across backends: ticket 016 (`soar_score_data_postgres`) asks whether drift table definitions are shared with this package or kept independent; this package's tables currently live in `lib/sqlite/contests_table.dart` (SQLite dialect) and would need to be promoted once that decision is made.
- A package README if ticket 013's per-project AGENTS.md covers this package.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)

## Sources

- `plan/architecture-requirements/offline-synchronization.md`
- `plan/architecture-requirements/data.md`
