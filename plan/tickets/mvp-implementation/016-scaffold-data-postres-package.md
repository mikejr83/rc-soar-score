# Ticket 016 — Scaffold `soar_score_data_postgres` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_data_postgres` is the server-side data access layer: PostgreSQL for the deployed API's persistent storage, using `drift` + `drift_postgres`. This gives the repository/codegen pattern parity with `soar_score_data_sqlite` — both packages are built on `drift`, just against different backends. It depends on `soar_score_core` for the types it persists and the repository interfaces it must implement.

This package only runs server-side (inside `soar_score_api_server`) and has no offline/embedded use case — but it does need to be able to accept and reconcile data synced up from offline `soar_score_data_sqlite` clients, so repository design should keep that reconciliation path in mind even if the sync logic itself is out of scope for this ticket.

## Work Items

- [ ] Create `packages/soar_score_data_postgres` with a `pubspec.yaml` (path dependency on `soar_score_core`).
- [ ] Establish folder structure in `lib/`:
  - `postgres/` — connection/pool setup, migrations, raw queries.
  - `repositories/` — one repository file per entity (will grow per domain entity), each implementing the corresponding abstract repository interface from `soar_score_core`.
- [ ] Add `drift`, `drift_postgres`, and `postgres` (the underlying driver `drift_postgres` wraps) as dependencies; add `drift_dev` + `build_runner` as dev dependencies for schema codegen.
- [ ] Add `build.yaml` configuring `drift_dev` codegen with the `postgres` dialect.
- [ ] Decide and record whether `drift` table definitions are shared with `soar_score_data_sqlite` (drift supports generating code for multiple dialects from the same schema) or maintained independently per package — this affects how the two data packages evolve together and is worth deciding deliberately rather than by default.
- [ ] Add `lib/soar_score_data_postgres.dart` exporting the public API.
- [ ] Add a config mechanism for connection details (host, port, credentials) that keeps secrets out of source control (e.g. environment variables), consistent with however `soar_score_api_server` is expected to be configured.
- [ ] Add one passing integration test against a real Postgres instance executing a trivial query, including running the initial migration.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.

## Acceptance Criteria

- [ ] Integration test passes against a Postgres instance provisioned in CI (e.g. `docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres` as a service container) — note this is structurally similar to how `drift_postgres` itself is tested upstream; document the setup required to run this package's tests locally and in CI.
- [ ] `dart analyze` passes with the path dependency on `soar_score_core` resolving.
- [ ] The `drift` + `drift_postgres` decision is recorded in this ticket and reflected in `pubspec.yaml`.
- [ ] Each scaffolded repository implements its corresponding `soar_score_core` interface.
- [ ] Connection configuration does not hard-code credentials in source.
- [ ] The shared-vs-independent schema decision (above) is explicitly recorded.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)

## Sources

- `plan/architecture-requirements/data.md`
- `plan/architecture-requirements/offline-synchronization.md`