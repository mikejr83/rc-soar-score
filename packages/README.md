# Soar Score Shared Packages

The [Soar Score](https://soar-score.ai) RC sailplane soaring contest scoring suite consists of six shared packages organized into three layers. All packages are pure Dart (except `soar_score_ui`, which is Flutter) and use drift's ORM, codegen, and repository patterns.

## API Layer

- [`soar_score_api`](./soar_score_api/README.md) — Shared API client with HTTP transport, HTTP-aware DTOs (JSON serialization via `json_annotation` + codegen), and typed connection errors. Provides `soar_score_api`'s documented contract.
- [`soar_score_api_handlers`](./soar_score_api_handlers/README.md) — Shared shelf routing table, hosted by either the deployed server or the embedded Windows API server. Expects repository interfaces from `soar_score_core`.

## Domain Layer

- [`soar_score_core`](./soar_score_core/README.md) — Domain models, business logic, and the scoring engine. Defines repository interfaces that the data layer implements. Uses the documented identifier requirements and business rules.

## Data Layer

- [`soar_score_data_sqlite`](./soar_score_data_sqlite/README.md) — Local/offline SQLite data access via `drift` ORM (Dart FFI bindings to `sqlite3`). Provides the SQLite-specific repository implementations. Schema includes the documented migration versioning.
- [`soar_score_data_postgres`](./soar_score_data_postgres/README.md) — Server-side PostgreSQL data access via `drift` + `drift_postgres`. Provides the server-side repository implementations targeting PostgreSQL.

## UI Layer

- [`soar_score_ui`](./soar_score_ui/README.md) — Shared Flutter UI package with reusable widgets and shared theme tokens. Used by both `soar_score_contest` and `soar_score_public` apps. No data access.

## Architecture overview

```heml
Flutter Apps (soar_score_contest, soar_score_public)
         ↓ 
soar_score_ui (shared Flutter widgets + theme)
         ↓
soar_score_api (shared HTTP client + DTOs)
         ↓
soar_score_api_handlers (shelf routing table)
         ↓
soar_score_core (domain models + business logic)
         ↓
soar_score_data_sqlite (local/offline)  ↔  soar_score_data_postgres (server-side)
```

The core package defines repository interfaces (`ContestRepository`). Each data package implements its own version of these interfaces (SQLite vs. PostgreSQL) using the same domain types. The API handlers layer is injected with the appropriate repository implementation, enabling the server to use PostgreSQL and the Windows embedded instance to use SQLite.