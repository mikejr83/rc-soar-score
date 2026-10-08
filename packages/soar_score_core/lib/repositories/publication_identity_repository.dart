import '../models/id.dart';
import '../models/publication/publication_identity.dart';

/// Abstract persistence contract for [PublicationIdentity]s.
///
/// Publications are backend only: they never synchronize, so writes record
/// no `MutationRecord`. Optimistic locking works as it does for synchronized
/// entities, through the `revision` the repository bumps.
abstract interface class PublicationIdentityRepository {
  Future<PublicationIdentity?> findById(Id id);

  /// The publication of [contestId], or `null` when it was never published.
  ///
  /// A publication outlives its contest (the contest id is cleared when the
  /// contest's working data is deleted), so a deleted contest has none.
  Future<PublicationIdentity?> findForContest(Id contestId);

  /// Every publication owned by [ownerPublicProfileId], oldest first.
  Future<List<PublicationIdentity>> listForOwner(Id ownerPublicProfileId);

  /// Stores [identity], bumping its revision, and returns it as stored.
  ///
  /// A new identity is stored at the revision it carries. Throws a
  /// `StaleRevisionError`, storing nothing, when [identity] was read at an
  /// older revision than the stored one.
  Future<PublicationIdentity> save(PublicationIdentity identity);
}
