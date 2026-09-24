# Data Postgres Package Agent Guide

PostgreSQL persistence for the deployed server. Uses drift ORM with drift_postgres adapter.

## Structure

- `lib/database.dart` — database schema, migrations, Drift database class
- `lib/repositories/` — repository implementations (one per entity)
- `lib/migrations/` — migration scripts
- `test/` — repository and database tests

## Boundaries

- **PostgreSQL mechanism: `drift` + `drift_postgres`.** All database operations go through Drift. Do not import `postgres` directly or execute raw SQL outside migrations.
- Server-side only; not intended for embedded use.

## Testing

- Tests require a Postgres instance (use testcontainers or local DB).
- Run: `dart test`