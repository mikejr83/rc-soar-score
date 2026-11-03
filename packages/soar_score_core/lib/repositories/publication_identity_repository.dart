import '../models/id.dart';
import '../models/publication/publication_identity.dart';

/// What the public listing asks for: filters, the page, and the order is
/// always the contest start, newest first.
class PublicationListQuery {
  const PublicationListQuery({
    this.name = '',
    this.venue = '',
    this.startsOnOrAfter,
    this.startsBefore,
    this.limit = 50,
    this.offset = 0,
  });

  /// Case-insensitive substring of the contest name; empty matches all.
  final String name;

  /// Case-insensitive substring of the venue; empty matches all.
  final String venue;

  /// Inclusive lower bound on the contest start (UTC).
  final DateTime? startsOnOrAfter;

  /// Exclusive upper bound on the contest start (UTC).
  final DateTime? startsBefore;

  final int limit;
  final int offset;
}

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

  /// The publications whose visibility is Public, that have been published
  /// and that match [query], ordered by contest start, newest first (ties by
  /// id). The database applies the filters and the page. Unlisted and
  /// Delisted ones are never returned, nor are records without a recorded
  /// contest start.
  Future<List<PublicationIdentity>> listPublic(PublicationListQuery query);

  /// How many Public, published publications have a contest that started
  /// before [startsBefore], on or after [startsOnOrAfter] when given, and
  /// that ended on or after [endsOnOrAfter] when given (a contest without an
  /// end counts as ending when it starts). The start bounds are the ones
  /// [listPublic] applies.
  Future<int> countPublicActive({
    DateTime? startsOnOrAfter,
    DateTime? endsOnOrAfter,
    required DateTime startsBefore,
  });

  /// Stores [identity], bumping its revision, and returns it as stored.
  ///
  /// A new identity is stored at the revision it carries. Throws a
  /// `StaleRevisionError`, storing nothing, when [identity] was read at an
  /// older revision than the stored one.
  Future<PublicationIdentity> save(PublicationIdentity identity);
}
