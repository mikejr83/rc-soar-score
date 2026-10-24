# Soar Score Shared Packages

The [Soar Score](https://soar-score.ai) RC sailplane soaring contest scoring suite consists of shared packages organized into three layers. All packages are pure Dart (except `soar_score_ui`, which is Flutter) and use drift's ORM, codegen, and repository patterns.

## API Layer

- [`soar_score_api`](./soar_score_api/README.md) — Shared API client with HTTP transport, HTTP-aware DTOs (JSON serialization via `json_annotation` + codegen), and typed connection errors. Provides `soar_score_api`'s documented contract.
- [`soar_score_api_handlers`](./soar_score_api_handlers/README.md) — Shared shelf routing table, hosted by either the deployed server or the embedded Windows API server. Expects repository interfaces from `soar_score_core`.

## Domain Layer

- [`soar_score_core`](./soar_score_core/README.md) — Domain models, business logic, and the scoring engine. Defines repository interfaces that the data layer implements. Uses the documented identifier requirements and business rules.

## Data Layer

- `soar_score_data` — Single data access package built on `drift`. The native offline application opens it against a local SQLite file (Dart FFI bindings to `sqlite3`); the server opens it against PostgreSQL via `drift_postgres`. The executor is chosen at database construction, so the schema, migrations and repositories are shared. Web applications do not use this package; they reach all data through the API.

## Sync Layer

- [`soar_score_sync`](./soar_score_sync/README.md) — Client synchronization engine for the native offline application: outbox, pull-first sync, write-through, cursor handling and status. Depends only on `soar_score_core` (including its `SyncStore` contract) and `soar_score_api`, never on `soar_score_data`. Used only by `soar_score_contest`, and only in its native bootstrap. The server-side acceptor lives in `soar_score_core` and `soar_score_data`, with routes in `soar_score_api_handlers`. Specified in `plan/architecture-requirements/sync-protocol.md`; see its [README](./soar_score_sync/README.md).

## UI Layer

- [`soar_score_ui`](./soar_score_ui/README.md) — Shared Flutter UI package with reusable widgets and shared theme tokens. Used by the `soar_score_contest` and `soar_score_self_score` apps; the public site (`soar_score_web`, Next.js) copies its fonts and logos. No data access.

## Architecture overview

```text
Flutter Apps (soar_score_contest, soar_score_self_score)
         ↓
soar_score_ui (shared Flutter widgets + theme)
         ↓
soar_score_api (shared HTTP client + DTOs)
         ↓
soar_score_api_handlers (shelf routing table)
         ↓
soar_score_core (domain models + business logic)
         ↓
soar_score_data (SQLite in the native app, PostgreSQL on the server)

soar_score_sync (native app only): soar_score_core + soar_score_api, storage via the SyncStore contract
```

The core package defines repository interfaces (`ContestRepository`). `soar_score_data` implements these interfaces once, using the same domain types, over either a SQLite or a PostgreSQL executor. The API handlers layer is injected with the appropriate repository implementation, enabling the server to use PostgreSQL and the Windows embedded instance to use SQLite.
