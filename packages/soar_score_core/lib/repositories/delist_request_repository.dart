import '../enums/delist_state.dart';
import '../models/id.dart';
import '../models/publication/delist_request.dart';

/// Abstract persistence contract for [DelistRequest]s.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class DelistRequestRepository {
  Future<DelistRequest?> findById(Id id);

  /// Every request for [publicationId], oldest first by id.
  Future<List<DelistRequest>> listForPublication(Id publicationId);

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
}
