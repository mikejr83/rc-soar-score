# Ticket 017 — Extract `soar_score_api_handlers` from `soar_score_server`

- **Category:** Refactor / Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

`apps/soar_score_server/lib/handler.dart`'s `createServerHandler()` (003, Done) currently builds the entire routing table — the `GET /health` payload and the `/api/v1` router — directly inside the deployable executable app. That's fine for a standalone server, but it blocks the architecture discussed for `soar_score_contest`'s Windows build (015): running the *same* API in-process, offline, with no deployed server reachable. A `shelf.Handler` factory that lives inside an executable app can't be depended on by another app.

This ticket extracts that routing logic into a new plain-Dart package, `packages/soar_score_api_handlers`, with no dependency on *how* it's served (`shelf_io.serve` on a bound port for `soar_score_server`, or hosted on `localhost` inside the Windows build per ticket 018) and no dependency on *which* data store backs it (`soar_score_data_postgres`, 016, server-side; `soar_score_data_sqlite`, 007, embedded). `apps/soar_score_server` becomes a thin executable: wire a repository implementation, call the factory, call `shelf_io.serve`.

## Decisions

- **Factory data dependency: required repository.** `buildApiHandler({required String name, required String displayName, required String version, required ContestRepository contests, AuthMiddleware? authMiddleware})`. The repository is mandatory from day one (per maintainer choice): the deployed server cannot start without a configured database (`POSTGRES_PASSWORD` unset → stderr message, exit 1). Consequence vs. ticket 003: `dart run lib/main.dart` in a dev environment with no Postgres configuration now fails fast instead of serving placeholder routes; with the variables set (any reachable or not — the connection is lazy, migrations run on first query) it serves the identical routes. The current placeholder routes execute no queries, so serving does not require a live instance.
- **Serving identity is caller-supplied.** The `name`/`displayName`/`version` values that previously lived as module globals in the old `soar_score_server/lib/health_handler.dart` now come from the factory arguments, so the deployed server and the embedded Windows instance (018) report themselves distinctly through the same routing code. The deployed server passes its existing values (`soar_score_server` / `Soar Score API Server` / `0.1.0`), preserving the 003 payload exactly.
- **`/health` payload is produced through the shared `HealthDto`.** `soar_score_api_handlers` takes a path dependency on `soar_score_api` (which transitively brings `json_annotation` for the DTO's generated code) so the server, the embedded instance, and the API client keep the compile-time shared type and cannot drift apart — exactly as the old server did. The handlers package does not depend on `shelf_io`, Flutter, or either data package.
- **Auth middleware placement: optional seam inside the package.** `buildApiHandler` accepts `authMiddleware: AuthMiddleware?`, a `Handler Function(Handler)` that wraps *only* the `/api/v1` subtree; `GET /health` always stays public (the ticket 010 carve-out). When omitted, `/api/v1` is unauthenticated — the embedded offline instance (018) therefore "simply never adds it", with no opt-out to implement. Ticket 010's JWT middleware will be built inside `soar_score_server` (it needs `AUTH0_DOMAIN`/JWKS config there) and passed through this seam.

## Work Items

- [x] Create `packages/soar_score_api_handlers` with a `pubspec.yaml` (path dependency on `soar_score_core` for repository interfaces/types; `shelf`, `shelf_router`). Also a path dependency on `soar_score_api` for the shared `HealthDto` (see Decisions).
- [x] Move the route-building logic out of `apps/soar_score_server/lib/handler.dart` into this package, exposing a factory (`buildApiHandler`) that takes its data dependencies as parameters rather than assuming a global or a concrete implementation.
- [x] Preserve the existing `GET /health` payload shape and the `/api/v1` router prefix (`/meta`, `/ping` placeholders) exactly, so `soar_score_server`'s existing behavior and tests are unaffected by the move. Verified live against the running server (see Verification).
- [x] Update `apps/soar_score_server` to depend on `packages/soar_score_api_handlers`; reduce its own `lib/main.dart`/`lib/handler.dart` to: wire `soar_score_data_postgres` repositories, call `buildApiHandler(...)`, and `shelf_io.serve(...)`.
- [x] Move `test/handler_test.dart`'s in-process routing tests from `apps/soar_score_server` into `packages/soar_score_api_handlers`, since they now test behavior that lives there; leave only wiring-level tests (if any) behind in the app. One wiring-level test remains (the `/health` round-trip through `createServerHandler`), following the no-Postgres skip convention of ticket 016's integration suites.
- [x] Decide where the eventual Auth0 JWT middleware (ticket 010) is applied — inside `soar_score_api_handlers` as an injectable/optional layer, or wrapped around the handler only in `apps/soar_score_server`'s `lib/main.dart`. The embedded Windows instance (018) likely shouldn't require a network auth token at all, so this decision determines whether 018 needs to opt out of something or simply never adds it. **Recorded: optional `authMiddleware` seam on the factory, applied to the `/api/v1` subtree only; 018 simply never adds one.**
- [x] Add `analysis_options.yaml` including `package:lints/recommended.yaml` to the new package.

## Acceptance Criteria

- [x] `apps/soar_score_server`'s externally-observable behavior is unchanged: `dart run lib/main.dart` still serves `GET /health` and the `/api/v1` placeholders identically; ticket 003's acceptance criteria still hold. Verified live with `PORT=9787` and `POSTGRES_PASSWORD` configured: `/health` → `{"name":"soar_score_server","displayName":"Soar Score API Server","version":"0.1.0"}`, `/api/v1/meta` → same identity payload, `/api/v1/ping` → `{"status":"ok"}`, unknown routes (`/api/v1/nope`, `/nope`) → 404. **Note:** per the required-repository decision, the executable now requires `POSTGRES_PASSWORD` to be set before it can serve (exits 1 with a stderr message when unset); ticket 003's "startable from the repo root" now reads "startable once the database environment is configured".
- [x] `dart test` passes in both `packages/soar_score_api_handlers` (in-process routing tests, no port binding; 7/7 pass) and `apps/soar_score_server` (wiring-level test, skips without `POSTGRES_PASSWORD`, matching ticket 016's convention).
- [x] `dart analyze` is clean in both (`--fatal-infos`; also clean workspace-wide via `melos analyze`).
- [x] `packages/soar_score_api_handlers` depends only on repository *interfaces* from `soar_score_core` — no dependency on `soar_score_data_postgres`, `soar_score_data_sqlite`, `shelf_io`, or Flutter — so it can be wired against either data package without modification.
- [x] The auth-middleware placement decision above is recorded (see Decisions).

## Files changed

- `packages/soar_score_api_handlers/pubspec.yaml` — new; name `soar_score_api_handlers`, version 0.1.0, `publish_to: none`, SDK `>=3.13.0 <4.0.0`; deps `shelf ^1.4.2`, `shelf_router ^1.1.4`, path deps on `soar_score_api` and `soar_score_core`; dev deps `lints ^6.1.0`, `test 1.31.1`. No `shelf_io`, no data-package or Flutter dependencies.
- `packages/soar_score_api_handlers/analysis_options.yaml` — new; includes `package:lints/recommended.yaml`.
- `packages/soar_score_api_handlers/.gitignore` — new; matches the other projects (`.dart_tool/`, `.packages`, `build/`).
- `packages/soar_score_api_handlers/lib/handler.dart` — new; `buildApiHandler({name, displayName, version, contests, authMiddleware})` (the factory), the `AuthMiddleware` typedef, and the auth seam behavior. Builds the top-level router: `/health` at `/`, the (optionally auth-wrapped) `/api/v1` stub router, 404 elsewhere.
- `packages/soar_score_api_handlers/lib/health_handler.dart` — moved from the app; `createHealthHandler(HealthDto identity)` + the shared `jsonResponse` helper, now identity-driven instead of module-global.
- `packages/soar_score_api_handlers/lib/stub_handler.dart` — moved from the app; `createStubApiHandler(HealthDto identity)` (the `/meta`, `/ping` placeholders), identity-driven.
- `packages/soar_score_api_handlers/lib/soar_score_api_handlers.dart` — new; barrel export, the package's only required import.
- `packages/soar_score_api_handlers/test/handler_test.dart` — the app's in-process routing tests moved here with identical expectations (payload shapes, 404s), plus 3 tests for the auth seam (401 without token, 200 with token, `/health` stays public with middleware configured).
- `packages/soar_score_api_handlers/test/stub_repository.dart` — new; small in-memory `ContestRepository` so the factory's required data dependency is satisfied without a data package (the placeholder routes execute no queries).
- `apps/soar_score_server/pubspec.yaml` — added path deps on `soar_score_api_handlers` and `soar_score_data_postgres`; removed `shelf_router` and `json_annotation` and the direct `soar_score_api` dependency (the app no longer uses them; the shared `HealthDto` flows through the handlers package).
- `apps/soar_score_server/lib/main.dart` — slimmed: `PORT` logic kept; now requires `PostgresConfig.fromEnvironment()` (exits 1 with a stderr message when unset), passes the config to `createServerHandler`, and `shelf_io.serve`s the result.
- `apps/soar_score_server/lib/handler.dart` — slimmed to wiring only: the server identity constants and `createServerHandler(PostgresConfig config)` = open `ContestDatabase` → `ContestPostgresRepository` → `buildApiHandler(...)`.
- `apps/soar_score_server/lib/health_handler.dart` — deleted (moved to the package, identity now supplied by the caller).
- `apps/soar_score_server/lib/stub_handler.dart` — deleted (moved to the package).
- `apps/soar_score_server/test/handler_test.dart` — rewritten as a wiring-level test: in-process `GET /health` through `createServerHandler` with the real PostgreSQL database/repo; skips when `POSTGRES_PASSWORD` is unset (ticket 016's skip convention), so `melos test` stays green without a Postgres instance.
- `pubspec.lock` — workspace lockfile updated by `melos bootstrap` for the new package.
- `plan/tickets/mvp-implementation/017-sqlite-sync-schema.md` — this ticket: status In-Review, decisions recorded, work items and acceptance criteria checked, files changed, verification, follow-ups.

## Verification

- `scripts/verify.ps1`: **PASSED** (bootstrap; format check across all 9 packages; `melos analyze --fatal-infos` clean in all 9; `melos test` — `soar_score_api_handlers` 7/7, `soar_score_server` wiring test skipped (no local Postgres), all other suites pass; `melos run build` builds both web apps and the server executable).
- `dart analyze` / `dart test` in both touched projects: clean, 7/7 (package); wiring test skipped (app, no Postgres configured on this machine).
- Live smoke: with `PORT=9787` and `POSTGRES_PASSWORD` set, `dart run lib/main.dart` served, and a live `GET` against each route returned byte-identical payloads to the pre-extraction server (`/health`, `/api/v1/meta`, `/api/v1/ping`; 404 for `/api/v1/nope` and `/nope`). Without `POSTGRES_PASSWORD`, the executable prints the configuration error and exits 1.

## Follow-ups

- Ticket 018 wires this package into the Windows target of `soar_score_contest`, using `soar_score_data_sqlite` (007) instead of `soar_score_data_postgres` (016); it also needs to supply the embedded instance's own serving identity to `buildApiHandler` and never pass an `authMiddleware`.
- Ticket 010 (Auth0 JWT middleware) should be written inside `apps/soar_score_server` against the `authMiddleware` seam established here (its JWKS/domain config lives server-side).
- **Ticket references to repair (separate scope, not done here):** ticket 018's Dependencies section links to a nonexistent `017-extract-api-handlers-package.md` (should point at this ticket's file); the mvp `README.md` index still carries the stale "SQLite Sync Schema" row for 017 and lists ticket 018's row also numbered 017.
- **Orphaned spec:** this file's original purpose — the local SQLite sync schema (mutation log, sync cursors, tombstones, revision/bookkeeping columns per `plan/architecture-requirements/offline-synchronization.md`) — was repurposed to this extraction by commit 2541de5 and is no longer ticketed. It needs its own new ticket number (the server-side Postgres reconciliation schema was already captured as a follow-up in ticket 016); tickets 007/016 and the mvp README index still point at this file (and its stale name) for that work.
- Replace the `/api/v1` placeholder endpoints with real business routes (feature tickets); they will be the first routes exercising the `ContestRepository` the factory now carries.

## Dependencies

- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) — code being extracted from (Done).
- [006-scaffold-core-package.md](006-scaffold-core-package.md) — repository interfaces.

## Sources

- `AGENTS.md`
- `plan/implementation-plan.md`
