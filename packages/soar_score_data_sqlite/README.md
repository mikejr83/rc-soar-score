# soar_score_data_sqlite

SQLite data access layer for the Soar Score RC sailplane scoring suite. Provides repositories and migration code for the embedded in-process SQLite instance used by the Windows desktop build's offline mode.

This is a pure Dart package that uses the `drift` ORM with `sqlite3` (Dart `dart:ffi` bindings). It is consumed by the Windows-embedded API server via `ContestSqliteRepository`:

```dart
import 'package:soar_score_data_sqlite/soar_score_data_sqlite.dart';

final db = ContestDatabase(path: 'contest.db');
final repo = ContestSqliteRepository(db);
```

## Packages

- `sqlite/` — SQLite database handling, table definitions (`Contests`), migrations, and raw query support
- `repositories/` — repository implementations that wrap core entities with SQLite storage logic

## Key types

- `ContestDatabase` — top-level SQLite database handle with migration management
- `ContestSqliteRepository` — repository wrapping SQLite for `Contest` operations
- `ContestData` — SQLite-specific row type for the `contests` table

## Configuration

No external configuration required — database path is passed at construction. For production use, consider environment variable for the database file path or a standard SQLite database name convention.

## Tests

```bash
cd packages/soar_score_data_sqlite
dart test
```