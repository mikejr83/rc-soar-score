# Data SQLite Package Agent Guide

Local SQLite persistence for offline use. Uses drift ORM.

## Structure

- `lib/database.dart` — database schema, migrations, Drift database class
- `lib/repositories/` — repository implementations (one per entity)
- `lib/migrations/` — migration scripts
- `test/` — repository and database tests

## Boundaries

- **SQLite mechanism: `drift` ORM.** All database operations go through Drift. Do not import `sqlite3` directly or execute raw SQL outside migrations.
- Pure Dart (no Flutter). Must work on Windows embedded instance and Linux server.

## Testing

- Repository tests use in-memory `db.open()` connections. No persistent test DB files.
- Run: `dart test`