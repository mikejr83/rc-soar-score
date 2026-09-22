# Ticket 003 — Scaffold `soar_score_server` (Dart/shelf)

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

The backend API is a Dart server using shelf, located at `apps/soar_score_server` (project name per `plan/implementation-plan.md`). It needs an entry point and a minimal working shelf server. Bulk command wiring is ticket 014's job, performed after the projects exist. Business endpoint design comes later; this ticket only establishes the runnable shell.

## Work Items

- [ ] Create `apps/soar_score_server` with a `pubspec.yaml` (Dart SDK compatible with the pinned Flutter/Dart from ticket 001; shelf, shelf_router, and `json_annotation` as baseline dependencies only — additional packages as needed later).
- [ ] Add `lib/main.dart` with a shelf `Handler` serving:
  - `GET /healthz` returning a JSON health payload (server name + version).
  - A `/api/v1/` router prefix with one or two placeholder endpoints.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.
- [ ] Add `test/` with an example passing test exercising the shelf `Handler` directly (no live server) for the health endpoint.
- [ ] Make the server startable from the repository root (e.g. running `lib/main.dart` from `apps/soar_score_server`).

## Acceptance Criteria

- [ ] `dart run lib/main.dart` serves on a configurable port (default 8080, overridable via env var) and `GET /healthz` returns 200 JSON.
- [ ] `dart test` passes against `soar_score_server`; `dart analyze` is clean.
- [ ] Health test runs against the `Handler` in-process (no port binding in tests).

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter/Dart pins for the SDK constraint.
- `plan/implementation-plan.md` — project name and directory convention.

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
