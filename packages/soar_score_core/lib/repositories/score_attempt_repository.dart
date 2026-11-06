import '../models/contest/contest.dart';
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

  /// The newest attempt at each of [scorePlaceholderIds] that has one, by
  /// placeholder id, in one read.
  Future<Map<Id, ScoreAttempt>> latestForPlaceholders(
    Iterable<Id> scorePlaceholderIds,
  );

  /// The attempts with the given [ids], by id, in one read. Unknown ids are
  /// left out.
  Future<Map<Id, ScoreAttempt>> findByIds(Iterable<Id> ids);

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
  /// With [contest], the contest is stored in the same transaction (the
  /// first accepted score moves a `Ready` contest to `Running`).
  ///
  /// Throws an `ArgumentError` if [placeholder] is not the attempt's, and a
  /// `StaleRevisionError` if it was read at an older revision.
  Future<ScoreAttempt> recordAttempt(
    ScoreAttempt attempt,
    ScorePlaceholder placeholder, {
    Contest? contest,
    required MutationMetadata metadata,
  });
}
