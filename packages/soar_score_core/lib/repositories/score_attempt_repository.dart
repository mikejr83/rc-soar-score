import '../models/id.dart';
import '../models/scores/score_attempt.dart';
import '../models/scores/score_placeholder.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ScoreAttempt]s.
///
/// Attempts are append-only: a correction is another attempt.
abstract interface class ScoreAttemptRepository {
  Future<ScoreAttempt?> findById(Id id);

  /// The attempt of [contestId] that carries [clientMutationId], or `null`.
  /// A retried submission finds its first attempt here.
  Future<ScoreAttempt?> findByClientMutationId(
    Id contestId,
    String clientMutationId,
  );

  /// The attempts at [scorePlaceholderId], oldest first.
  Future<List<ScoreAttempt>> listForPlaceholder(Id scorePlaceholderId);

  /// The newest attempt at [scorePlaceholderId], or `null` when there is none.
  Future<ScoreAttempt?> latestForPlaceholder(Id scorePlaceholderId);

  /// Stores a new [attempt].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored.
  Future<ScoreAttempt> append(
    ScoreAttempt attempt, {
    required MutationMetadata metadata,
  });

  /// Stores [attempt] and the updated [placeholder] it belongs to, in one
  /// transaction, so the placeholder never shows a state its attempts do not
  /// back.
  ///
  /// Throws an `ArgumentError` if [placeholder] is not the attempt's, and a
  /// `StaleRevisionError` if it was read at an older revision.
  Future<ScoreAttempt> recordAttempt(
    ScoreAttempt attempt,
    ScorePlaceholder placeholder, {
    required MutationMetadata metadata,
  });
}
