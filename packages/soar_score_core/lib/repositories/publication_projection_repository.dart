import '../models/id.dart';
import '../models/publication/publication_projection.dart';

/// Abstract persistence contract for [PublicationProjection]s.
///
/// Projections are immutable: a republish adds the next revision and never
/// edits one. They are backend only, so writes record no `MutationRecord`.
abstract interface class PublicationProjectionRepository {
  Future<PublicationProjection?> findById(Id id);

  /// Every projection of [publicationId], oldest revision first.
  Future<List<PublicationProjection>> listForPublication(Id publicationId);

  /// The projection of [publicationId] with the highest revision, or `null`
  /// when it has none.
  Future<PublicationProjection?> latestForPublication(Id publicationId);

  /// The projection a publish request with [clientMutationId] created, or
  /// `null`. A retried publish returns this instead of creating a second one.
  Future<PublicationProjection?> findByClientMutationId(
    Id publicationId,
    String clientMutationId,
  );

  /// Stores a new [projection].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored. A
  /// second projection with the same (publication, revision) or
  /// (publication, client mutation id) is refused by the database.
  Future<PublicationProjection> append(PublicationProjection projection);
}
