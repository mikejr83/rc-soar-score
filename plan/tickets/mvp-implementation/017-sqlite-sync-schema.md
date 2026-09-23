# Ticket 017 — Extract `soar_score_api_handlers` from `soar_score_server`

- **Category:** Refactor / Scaffold
- **Priority:** High
- **Status:** Open

## Context

`apps/soar_score_server/lib/handler.dart`'s `createServerHandler()` (003, Done) currently builds the entire routing table — the `GET /health` payload and the `/api/v1` router — directly inside the deployable executable app. That's fine for a standalone server, but it blocks the architecture discussed for `soar_score_contest`'s Windows build (015): running the *same* API in-process, offline, with no deployed server reachable. A `shelf.Handler` factory that lives inside an executable app can't be depended on by another app.

This ticket extracts that routing logic into a new plain-Dart package, `packages/soar_score_api_handlers`, with no dependency on *how* it's served (`shelf_io.serve` on a bound port for `soar_score_server`, or hosted on `localhost` inside the Windows build per ticket 018) and no dependency on *which* data store backs it (`soar_score_data_postgres`, 016, server-side; `soar_score_data_sqlite`, 007, embedded). `apps/soar_score_server` becomes a thin executable: wire a repository implementation, call the factory, call `shelf_io.serve`.

## Work Items

- [ ] Create `packages/soar_score_api_handlers` with a `pubspec.yaml` (path dependency on `soar_score_core` for repository interfaces/types; `shelf`, `shelf_router`).
- [ ] Move the route-building logic out of `apps/soar_score_server/lib/handler.dart` into this package, exposing a factory (e.g. `Handler buildApiHandler({required SomeRepository repo, ...})`) that takes its data dependencies as parameters rather than assuming a global or a concrete implementation.
- [ ] Preserve the existing `GET /health` payload shape and the `/api/v1` router prefix (`/meta`, `/ping` placeholders) exactly, so `soar_score_server`'s existing behavior and tests are unaffected by the move.
- [ ] Update `apps/soar_score_server` to depend on `packages/soar_score_api_handlers`; reduce its own `lib/main.dart`/`lib/handler.dart` to: wire `soar_score_data_postgres` repositories, call `buildApiHandler(...)`, and `shelf_io.serve(...)`.
- [ ] Move `test/handler_test.dart`'s in-process routing tests from `apps/soar_score_server` into `packages/soar_score_api_handlers`, since they now test behavior that lives there; leave only wiring-level tests (if any) behind in the app.
- [ ] Decide where the eventual Auth0 JWT middleware (ticket 010) is applied — inside `soar_score_api_handlers` as an injectable/optional layer, or wrapped around the handler only in `apps/soar_score_server`'s `lib/main.dart`. The embedded Windows instance (018) likely shouldn't require a network auth token at all, so this decision determines whether 018 needs to opt out of something or simply never adds it. Record the decision here.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml` to the new package.

## Acceptance Criteria

- [ ] `apps/soar_score_server`'s externally-observable behavior is unchanged: `dart run lib/main.dart` still serves `GET /health` and the `/api/v1` placeholders identically; ticket 003's acceptance criteria still hold.
- [ ] `dart test` passes in both `packages/soar_score_api_handlers` (in-process routing tests, no port binding) and `apps/soar_score_server` (whatever thin wiring remains there).
- [ ] `dart analyze` is clean in both.
- [ ] `packages/soar_score_api_handlers` depends only on repository *interfaces* from `soar_score_core` — no dependency on `soar_score_data_postgres`, `soar_score_data_sqlite`, `shelf_io`, or Flutter — so it can be wired against either data package without modification.
- [ ] The auth-middleware placement decision above is recorded.

## Dependencies

- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) — code being extracted from (Done).
- [006-scaffold-core-package.md](006-scaffold-core-package.md) — repository interfaces.

## Follow-ups

- Ticket 018 wires this package into the Windows target of `soar_score_contest`, using `soar_score_data_sqlite` (007) instead of `soar_score_data_postgres` (016).
- Ticket 010 (Auth0 JWT middleware) should be written against wherever this ticket decides middleware lives.

## Sources

- `AGENTS.md`
- `plan/implementation-plan.md`