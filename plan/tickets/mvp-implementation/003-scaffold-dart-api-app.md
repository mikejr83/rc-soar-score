# Ticket 003 — Scaffold `soar_score_server` (Dart/shelf)

- **Category:** Scaffold
- **Priority:** High
- **Status:** Done

> **Endpoint change (2026-09-22):** during implementation the maintainer changed the health endpoint from `GET /healthz` to `GET /health`. Ticket text below reflects `GET /health`; the other tickets that referenced the old path were updated the same day (see Follow-ups).

## Context

The backend API is a Dart server using shelf, located at `apps/soar_score_server` (project name per `plan/implementation-plan.md`). It needs an entry point and a minimal working shelf server. Bulk command wiring is ticket 014's job, performed after the projects exist. Business endpoint design comes later; this ticket only establishes the runnable shell.

## Work Items

- [x] Create `apps/soar_score_server` with a `pubspec.yaml` (Dart SDK compatible with the pinned Flutter/Dart from ticket 001; shelf, shelf_router, and `json_annotation` as baseline dependencies only — additional packages as needed later).
- [x] Add `lib/main.dart` with a shelf `Handler` serving:
  - `GET /health` returning a JSON health payload (server name + version). Payload shape: `{ "name": "soar_score_server", "displayName": "Soar Score API Server", "version": "0.1.0" }` (both names per plan's project table, decided during review).
  - A `/api/v1/` router prefix with one or two placeholder endpoints (`GET /api/v1/meta`, `GET /api/v1/ping`).
- [x] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.
- [x] Add `test/` with an example passing test exercising the shelf `Handler` directly (no live server) for the health endpoint.
- [x] Make the server startable from the repository root (e.g. running `lib/main.dart` from `apps/soar_score_server`). `apps/soar_score_server` has no per-project AGENTS.md yet (ticket 013); the README-level guide is sufficient.

## Acceptance Criteria

- [x] `dart run lib/main.dart` serves on a configurable port (default 8080, overridable via the `PORT` env var, decided during review) and `GET /health` returns 200 JSON. Verified live: default 8080 and `PORT=9787` override both serve `{"name":"soar_score_server","displayName":"Soar Score API Server","version":"0.1.0"}`.
- [x] `dart test` passes against `soar_score_server`; `dart analyze` is clean. Verified: `dart analyze` → "No issues found!"; `dart test` → 4/4 passing.
- [x] Health test runs against the `Handler` in-process (no port binding in tests). The test calls `createServerHandler()` directly on an in-memory request.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter/Dart pins for the SDK constraint.
- `plan/implementation-plan.md` — project name and directory convention.

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`

## Files changed

- `apps/soar_score_server/pubspec.yaml` — new; baseline deps `shelf ^1.4.2`, `shelf_router ^1.1.4`, `json_annotation ^4.12.0` (versions as resolved by `dart pub add` on Dart 3.13.3); dev deps `lints ^6.1.0`, `test ^1.32.0`; SDK `>=3.13.0 <4.0.0`.
- `apps/soar_score_server/pubspec.lock` — new; committed for reproducible CI builds (consumed by ticket 011).
- `apps/soar_score_server/.gitignore` — new; ignores `.dart_tool/`, `.packages`, `build/`.
- `apps/soar_score_server/analysis_options.yaml` — new; includes `package:lints/recommended.yaml`.
- `apps/soar_score_server/lib/main.dart` — new; entry point: reads `PORT` (default 8080, invalid values fall back to 8080 with a stderr warning), starts `shelf_io.serve` on the top-level handler.
- `apps/soar_score_server/lib/handler.dart` — new; `createServerHandler()` (`Handler`) serving `GET /health` (JSON: `name`, `displayName`, `version`) and a `shelf_router` `Router` mounted at `/api/v1` with placeholders `GET /meta` and `GET /ping`; unknown routes return 404.
- `apps/soar_score_server/test/handler_test.dart` — new; in-process Handler tests for `/health`, both `/api/v1` placeholders, and 404 behavior (no port binding).
- `plan/tickets/mvp-implementation/003-scaffold-dart-api-app.md` — this ticket: status Done, endpoint change note, work items/acceptance criteria checked, files listed.

## Follow-ups

- ~~Rename `/healthz` to `/health` in the tickets that still reference the old path: 010 (the JWT middleware carve-out for the public health route), and the mvp README's execution-order note ("its `/healthz` is the contract `soar_score_api`'s example DTO targets").~~ — done (2026-09-22; ticket 012's reference is in rejected historical text; left as-is.)
- Wire `soar_score_api`'s `HealthDto` to the actual payload shape (ticket 008); the payload now carries `displayName` in addition to `name` + `version`.
- Replace the `/api/v1` placeholder endpoints with real business routes (feature tickets), and consume the baseline `json_annotation` dep for serialized DTOs.
- Add Auth0 JWT middleware (ticket 010): `/health` stays unauthenticated; `/api/v1` routes require a valid token.
- Connect this app to the Melos workspace and bulk commands (ticket 014); add the per-project AGENTS.md (ticket 013).
- CI build/test coverage for this app lands with the root workflow (ticket 011).
