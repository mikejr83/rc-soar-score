import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/repositories/unique_violation.dart';
import 'package:soar_score_data/sync/drift_sync_acceptor_store.dart';
import 'package:sqlite3/common.dart' show SqliteException;
import 'package:test/test.dart';

SqliteException _sqlite(int code, String message) =>
    SqliteException(extendedResultCode: code, message: message);

void main() {
  group('constraintViolationKind', () {
    test('reads the SQLite extended result code', () {
      expect(
        constraintViolationKind(_sqlite(2067, 'UNIQUE constraint failed')),
        ConstraintViolationKind.unique,
      );
      expect(
        constraintViolationKind(_sqlite(1555, 'UNIQUE constraint failed')),
        ConstraintViolationKind.unique,
      );
      expect(
        constraintViolationKind(_sqlite(787, 'FOREIGN KEY constraint failed')),
        ConstraintViolationKind.foreignKey,
      );
      expect(constraintViolationKind(_sqlite(1299, 'NOT NULL')), isNull);
    });

    test('looks through drift\'s wrapper', () {
      expect(
        constraintViolationKind(
          DriftWrappedException(
            message: 'x',
            cause: _sqlite(2067, 'UNIQUE constraint failed'),
          ),
        ),
        ConstraintViolationKind.unique,
      );
    });

    test('never reads the message of an error that is not the database', () {
      for (final text in [
        'no Contest with id 019a-b12db6235050 and 23505 and 23503',
        'unique constraint, duplicate key, foreign key',
      ]) {
        expect(constraintViolationKind(Exception(text)), isNull);
        expect(constraintViolationKind(StateError(text)), isNull);
        expect(isUniqueViolation(Exception(text)), isFalse);
        expect(asConstraintError(Exception(text)), isNull);
      }
      expect(
        asConstraintError(
          core.EntityNotFoundError(
            entityType: 'Contest',
            entityId: core.Id.parse('01900000-0000-7000-8000-000023505000'),
          ),
        ),
        isNull,
      );
    });

    test('maps to the sync constraint error', () {
      expect(
        asConstraintError(_sqlite(2067, 'x')),
        isA<core.SyncConstraintError>().having(
          (e) => e.kind,
          'kind',
          core.SyncConstraintKind.unique,
        ),
      );
      expect(
        asConstraintError(_sqlite(787, 'x')),
        isA<core.SyncConstraintError>().having(
          (e) => e.kind,
          'kind',
          core.SyncConstraintKind.foreignKey,
        ),
      );
    });
  });
}
