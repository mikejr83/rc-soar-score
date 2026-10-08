import '../models/id.dart';
import '../models/sync/audit_event.dart';

/// Abstract persistence contract for [AuditEvent]s.
///
/// The audit trail is append-only: an event is never edited or deleted.
abstract interface class AuditEventRepository {
  Future<AuditEvent?> findById(Id id);

  /// Every event of [publicationId], oldest first by server time.
  Future<List<AuditEvent>> listForPublication(Id publicationId);

  /// Stores a new [event].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored.
  Future<AuditEvent> append(AuditEvent event);
}
