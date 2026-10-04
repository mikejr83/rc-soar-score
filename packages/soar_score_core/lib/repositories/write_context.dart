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
}
