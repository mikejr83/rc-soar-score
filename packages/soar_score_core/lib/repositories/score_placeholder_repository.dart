import '../models/id.dart';
import '../models/scores/score_placeholder.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ScorePlaceholder]s.
abstract interface class ScorePlaceholderRepository {
  Future<ScorePlaceholder?> findById(Id id);

  /// The placeholder of [assignmentId], or `null`; an assignment has at most
  /// one.
  Future<ScorePlaceholder?> findForAssignment(Id assignmentId);

  /// Like [findForAssignment], and keeps the row locked until the enclosing
  /// transaction ends (PostgreSQL `FOR UPDATE`), so a writer outside the
  /// contest gate waits for it. Call it first, before any other read of the
  /// slot, inside `OfficialScoreRepository.withContestGate`.
  Future<ScorePlaceholder?> findForAssignmentForUpdate(Id assignmentId);

  /// The placeholders of [contestId], in the order they were created.
  Future<List<ScorePlaceholder>> listForContest(Id contestId);

  /// The placeholders of [contestParticipationId], in the order they were
  /// created.
  Future<List<ScorePlaceholder>> listForParticipation(
    Id contestParticipationId,
  );

  /// Inserts [placeholder], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Returns the placeholder as stored.
  Future<ScorePlaceholder> save(
    ScorePlaceholder placeholder, {
    required MutationMetadata metadata,
  });

  /// Deletes the placeholder with [id]; returns whether a row was removed.
  ///
  /// A placeholder that has attempts or official scores cannot be deleted.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
