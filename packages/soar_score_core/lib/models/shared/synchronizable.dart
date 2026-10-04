import '../id.dart';
import 'sync_scoped.dart';

/// An entity that travels through synchronization and carries a revision.
///
/// The unit of work needs [id] and [entityType] to store the entity and write
/// its `MutationRecord` or `Tombstone`.
abstract interface class Synchronizable implements SyncScoped {
  /// Primary key.
  Id get id;

  /// Stable name of the entity type, as written in `MutationRecord.entity_type`.
  String get entityType;

  /// Revision counter used for optimistic locking.
  ///
  /// Models never bump it; the unit of work does.
  int get revision;
}
