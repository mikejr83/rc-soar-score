# Ticket 007 — Scaffold `soar_score_data` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_data` is the data access layer: SQLite for local/offline storage and HTTP for talking to the API (`AGENTS.md`). It will hold repositories, SQLite migration code, and an HTTP client. This ticket creates the package skeleton with the folder structure and an in-memory example repository so the repository pattern exists before real repositories are written. It depends on `soar_score_core` for the types it persists.

## Work Items

- [ ] Create `packages/soar_score_data` with a `pubspec.yaml` (path dependency on `soar_score_core`).
- [ ] Establish folder structure in `lib/`:
  - `sqlite/` — database open, migrations, raw queries.
  - `repositories/` — one repository file per entity (will grow per domain entity).
  - `http/` — API client (token handling added later with Auth0).
- [ ] Add a minimal `Database`/`DatabaseExecutor` abstraction or use `drift`/`sqflite_common_ffi` decision — decide which SQLite mechanism to standardize on and record the choice here (do not pick one that is web-incompatible by default, since the contest app is a web target).
  - **Decision record:** _fill in at execution time._
- [ ] Add `lib/soar_score_data.dart` exporting the public API.
- [ ] Add one passing unit test against an in-memory database executing a trivial query.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.

## Acceptance Criteria

- [ ] In-memory database test passes without requiring a native SQLite binary in CI.
- [ ] `dart analyze` passes with the path dependency on `soar_score_core` resolving.
- [ ] The SQLite mechanism decision is recorded in this ticket and reflected in `pubspec.yaml`.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)

## Sources

- `AGENTS.md`
- `plan/architecture-requirements/offline-synchronization.md`
- `plan/architecture-requirements/data.md`
