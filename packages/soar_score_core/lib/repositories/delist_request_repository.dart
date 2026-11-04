import '../enums/delist_state.dart';
import '../models/id.dart';
import '../models/publication/delist_request.dart';
import '../models/sync/audit_event.dart';

/// Abstract persistence contract for [DelistRequest]s.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class DelistRequestRepository {
  Future<DelistRequest?> findById(Id id);

  /// Every request for [publicationId], oldest first by id.
  Future<List<DelistRequest>> listForPublication(Id publicationId);

  /// The request of [publicationId] with the highest id (the newest), in any
  /// state, or `null`.
  Future<DelistRequest?> findLatestForPublication(Id publicationId);

  /// The pending request for [publicationId], or `null`. A publication has
  /// at most one.
  Future<DelistRequest?> findPendingForPublication(Id publicationId);

  /// Every request in [state] across publications, in id order, for the
  /// administrator's queue.
  Future<List<DelistRequest>> listByState(DelistState state);

  /// Stores [request], replacing the stored one with the same id (a decision
  /// is a save of the decided copy).
  ///
  /// A second pending request for a publication is refused by the database.
  Future<DelistRequest> save(DelistRequest request);

  /// Stores a new pending [request] and its [audit] event together, all or
  /// nothing.
  ///
  /// When the publication already has a pending request, even one created
  /// by a caller racing this one, nothing is stored and that request comes
  /// back with `created` false.
  Future<({DelistRequest request, bool created})> createPending(
    DelistRequest request,
    AuditEvent audit,
  );

  /// Stores [request] (the same request in a new state) and its [audit]
  /// event together, all or nothing.
  Future<DelistRequest> saveWithAudit(DelistRequest request, AuditEvent audit);
}
