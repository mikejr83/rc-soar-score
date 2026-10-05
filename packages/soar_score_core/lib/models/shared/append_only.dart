import '../id.dart';
import 'sync_scoped.dart';

/// An entity that is written once and never changed: it has a scope but no
/// revision, so it implements this and not `Synchronizable`.
///
/// The unit of work stores it with `append`, which refuses a second write of
/// the same [id].
abstract interface class AppendOnly implements SyncScoped {
  /// Primary key.
  Id get id;

  /// Stable name of the entity type, as written in `MutationRecord.entity_type`.
  String get entityType;
}
