import '../models/contest/contest.dart';
import '../models/id.dart';
import '../models/sync/audit_event.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [Contest] entities.
///
/// `soar_score_core` owns only the contract; the implementations live in the
/// data package, so callers depend on this and never on how it is stored.
/// Reads are direct. Writes go through the `UnitOfWork` of the implementation,
/// which bumps the revision and records the mutation, so every write names who
/// made it.
abstract interface class ContestRepository {
  /// Loads a single contest by [id], or `null` when none exists.
  Future<Contest?> findById(Id id);

  /// Loads every persisted contest.
  Future<List<Contest>> getAll();

  /// Inserts [contest], or updates the stored row with the same id.
  ///
  /// The stored revision is bumped and a mutation is recorded. Throws a
  /// `StaleRevisionError` when [contest] was read at an older revision.
  /// Returns the contest as stored.
  ///
  /// An [audit] event is stored in the same transaction as the contest, so
  /// either both are kept or neither is.
  Future<Contest> save(
    Contest contest, {
    required MutationMetadata metadata,
    AuditEvent? audit,
  });

  /// Deletes the contest with [id], recording a tombstone and a mutation;
  /// returns whether a row was removed.
  Future<bool> delete(Id id, {required MutationMetadata metadata});

  /// Releases the underlying storage connection.
  Future<void> close();
}
