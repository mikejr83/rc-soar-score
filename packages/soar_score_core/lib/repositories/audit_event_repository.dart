import '../enums/audit_action.dart';
import '../models/id.dart';
import '../models/sync/audit_event.dart';

/// Abstract persistence contract for [AuditEvent]s.
///
/// The audit trail is append-only: an event is never edited or deleted.
abstract interface class AuditEventRepository {
  Future<AuditEvent?> findById(Id id);

  /// Every event of [publicationId], oldest first by server time.
  Future<List<AuditEvent>> listForPublication(Id publicationId);

  /// Which of [revisions] of [publicationId] were published by the system
  /// (the director's update mode): the resulting revisions of its successful
  /// publish attempts made under system authority. Reads only those
  /// revisions, never the whole trail.
  Future<Set<int>> systemPublishRevisions(
    Id publicationId,
    Iterable<int> revisions,
  );

  /// The events of [contestId], newest first by server time.
  ///
  /// [action] keeps only events of that kind, [offset] skips that many of
  /// the matching events and [limit] keeps the first that many after them.
  Future<List<AuditEvent>> listForContest(
    Id contestId, {
    AuditAction? action,
    int? limit,
    int? offset,
  });

  /// Stores a new [event].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored.
  Future<AuditEvent> append(AuditEvent event);
}
