# soar_score_data_postgres

PostgreSQL data access layer for the Soar Score RC sailplane scoring suite. Provides server-side repositories and migration code for the deployed API's persistent storage.

This pure Dart package uses the `drift` ORM with `drift_postgres` to run against PostgreSQL. It provides `ContestPostgresRepository` and `ContestDatabase` implementations:

```dart
import 'package:soar_score_data_postgres/soar_score_data_postgres.dart';

final config = PostgresConfig.fromEnvironment();
final db = ContestDatabase(config);
final repo = ContestPostgresRepository(db);
```

## Packages

- `postgres/` — PostgreSQL connection setup (via `PostgresConfig`), migrations, table definitions (`Contests`), and raw query support
- `repositories/` — repository implementations that wrap core entities with PostgreSQL storage logic

## Key types

- `ContestDatabase` — top-level PostgreSQL database handle with migration management
- `ContestPostgresRepository` — repository wrapping PostgreSQL for `Contest` operations
- `PostgresConfig` — connection configuration from environment variables
- `ContestData` — PostgreSQL-specific row type for the `contests` table

## Environment variables

The package reads these environment variables from `PostgresConfig.fromEnvironment()`:

- `POSTGRES_HOST` — host (defaults to `localhost`)
- `POSTGRES_PORT` — port (defaults to `5432`)
- `POSTGRES_DB` — database name (defaults to `postgres`)
- `POSTGRES_USER` — username (defaults to `postgres`)
- `POSTGRES_PASSWORD` — password (required)
- `POSTGRES_SSLMODE` — SSL mode (`disable`, `require`, `verifyFull`; defaults to `disable`)

## Tests

Integration tests require a real Postgres instance. Set up a local database (e.g., via Docker) and configure `POSTGRES_PASSWORD`:

```bash
# Start a Postgres instance
docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres

# Set environment variables for tests
export POSTGRES_PASSWORD=postgres
export POSTGRES_DB=test
export POSTGRES_USER=postgres

# Run tests
cd packages/soar_score_data_postgres
dart test
```