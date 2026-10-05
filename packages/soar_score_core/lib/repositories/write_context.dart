import '../models/landing/landing_table_with_results.dart';
import '../models/matrix/matrix_assignment.dart';
import '../models/shared/append_only.dart';
import '../models/shared/synchronizable.dart';
import 'mutation_metadata.dart';

/// The writes available inside a [UnitOfWork].
abstract interface class WriteContext {
  /// Stores [entity], bumps its revision, and records a `MutationRecord`, all
  /// in the surrounding transaction. Returns the entity as stored.
  Future<T> save<T extends Synchronizable>(
    T entity, {
    required MutationMetadata metadata,
  });

  /// Deletes [entity] and records a `Tombstone` and a `MutationRecord` in the
  /// surrounding transaction.
  Future<void> delete(
    Synchronizable entity, {
    required MutationMetadata metadata,
  });

  /// Stores a new append-only [entity] and records a `MutationRecord`.
  ///
  /// Throws an `AlreadyStoredError` if an entity with the same id is stored.
  Future<T> append<T extends AppendOnly>(
    T entity, {
    required MutationMetadata metadata,
  });

  /// Stores a new director-owned landing [table] with its entries and records
  /// one `MutationRecord` whose payload carries the entries too.
  ///
  /// Throws an `AlreadyStoredError` if the table id is stored, and an
  /// `ArgumentError` if the table has no owner, because system tables are
  /// seeded, not written locally.
  Future<LandingTableWithResults> appendLandingTable(
    LandingTableWithResults table, {
    required MutationMetadata metadata,
  });

  /// Stores [moved], an assignment of type `Moved`, and sets
  /// `superseded_by_assignment_id` on the assignment it moves from, which is
  /// its `sourceAssignmentId`. One `MutationRecord` covers both.
  ///
  /// This is the only update an assignment ever gets. It throws an
  /// `AlreadySupersededError` if the source was already moved, and an
  /// `ArgumentError` if [moved] is not a `Moved` assignment or its source is
  /// not stored.
  Future<MatrixAssignment> moveAssignment(
    MatrixAssignment moved, {
    required MutationMetadata metadata,
  });
}
