import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:postgres/postgres.dart' show ServerException;
import 'package:sqlite3/common.dart' show SqliteException;

/// The kind of integrity rule a database error broke.
enum ConstraintViolationKind { unique, foreignKey }

/// SQLite extended result codes: `SQLITE_CONSTRAINT_UNIQUE`,
/// `SQLITE_CONSTRAINT_PRIMARYKEY` and `SQLITE_CONSTRAINT_FOREIGNKEY`.
const _sqliteUnique = 2067;
const _sqlitePrimaryKey = 1555;
const _sqliteForeignKey = 787;

/// The kind of integrity rule [error] broke on either backend, or null when
/// it is not the database refusing a unique or foreign-key rule.
///
/// Decided from the driver's own code (the SQLite extended result code or the
/// PostgreSQL SQLSTATE — `23505` is a unique violation, `23503` is a foreign
/// key violation), never from the message text: a message can carry user
/// data, such as an id that happens to contain `23505`, and an error that is
/// not from the database at all (a not-found, say) must stay what it is.
ConstraintViolationKind? constraintViolationKind(Object? error) {
  switch (error) {
    case ServerException(:final code):
      return switch (code) {
        '23505' => ConstraintViolationKind.unique,
        '23503' => ConstraintViolationKind.foreignKey,
        _ => null,
      };
    case SqliteException(:final extendedResultCode):
      return switch (extendedResultCode) {
        _sqliteUnique || _sqlitePrimaryKey => ConstraintViolationKind.unique,
        _sqliteForeignKey => ConstraintViolationKind.foreignKey,
        _ => null,
      };
    case DriftWrappedException(:final cause):
      return constraintViolationKind(cause);
    default:
      return null;
  }
}

/// Whether [error] is a broken unique rule on either backend.
bool isUniqueViolation(Object? error) =>
    constraintViolationKind(error) == ConstraintViolationKind.unique;
