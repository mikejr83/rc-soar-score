import '../models/id.dart';
import '../models/scores/review_request.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ReviewRequest]s.
///
/// Review requests are never deleted: decided and superseded ones stay as
/// the review history of the score they were made on.
abstract interface class ReviewRequestRepository {
  Future<ReviewRequest?> findById(Id id);

  /// The review requests of [contestId], oldest first by id.
  Future<List<ReviewRequest>> listForContest(Id contestId);

  /// The review requests of [scorePlaceholderId], oldest first by id.
  Future<List<ReviewRequest>> listForScorePlaceholder(Id scorePlaceholderId);

  /// The request of [scorePlaceholderId] still waiting on a decision
  /// (`Submitted` or `UnderReview`), or `null`; a score has at most one.
  Future<ReviewRequest?> findOpenForScorePlaceholder(Id scorePlaceholderId);

  /// The requests of [contestId] still waiting on a decision, oldest first
  /// by id.
  Future<List<ReviewRequest>> listOpenForContest(Id contestId);

  /// Inserts [request], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Throws an `ArgumentError` when its contest is not the contest of its
  /// score placeholder, and an `EntityNotFoundError` when the placeholder is
  /// not stored. The database refuses a second open request for a score.
  /// Returns the request as stored.
  Future<ReviewRequest> save(
    ReviewRequest request, {
    required MutationMetadata metadata,
  });
}
