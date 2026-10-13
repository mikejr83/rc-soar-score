# Sync Package Agent Guide

The client sync engine for the native contest application. It follows `plan/architecture-requirements/sync-protocol.md`.

## Structure

- `lib/soar_score_sync.dart` — the public library; consumers import only this
- `lib/src/` — the engine, scheduler, gateway, state types and mappers
- `test/` — tests against an in-memory fake store and a fake gateway

## Boundaries

- **Pure Dart, no Flutter, no `dart:io`.** The engine runs on any Dart runtime.
- **Depends only on `soar_score_core` and `soar_score_api`.** It must not depend on `soar_score_data`: it reaches local storage through the `SyncStore` and `ReplicatedChangeApplier` contracts defined in core, so drift, `sqlite3` and `drift_postgres` never enter its dependency closure.
- **Only `apps/soar_score_contest` may depend on this package, and only its native bootstrap may import it.** `soar_score_server`, `soar_score_api_handlers`, `soar_score_ui` and the other apps must not depend on it. The web build contains no engine.
- Tokens come from the `ApiClient` the engine is given; the engine never stores or refreshes one.

## Testing

- Unit tests use `FakeSyncStore`, `FakeApplier` and `FakeGateway` from `test/support/`.
- `test/architecture/` checks the boundaries above.
- Run: `dart test`
