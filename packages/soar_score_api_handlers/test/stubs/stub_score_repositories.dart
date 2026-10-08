import 'package:soar_score_core/soar_score_core.dart';

import 'stub_contest_repository.dart';
import 'stub_matrix_repositories.dart';

/// Score attempts in memory, for tests to inspect.
class StubScoreAttemptRepository implements ScoreAttemptRepository {
  final List<ScoreAttempt> stored = [];

  @override
  Future<ScoreAttempt?> findByClientMutationId(
    Id contestId,
    String clientMutationId,
  ) async => stored
      .where(
        (attempt) =>
            attempt.contestId == contestId &&
            attempt.clientMutationId == clientMutationId,
      )
      .firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Official scores in memory. [recordEntry] behaves like the real one where
/// handlers depend on it: a placeholder or contest read at an older revision
/// is refused with a [StaleRevisionError] and nothing is stored.
class StubOfficialScoreRepository implements OfficialScoreRepository {
  StubOfficialScoreRepository(
    this._contests,
    this._placeholders,
    this._attempts,
  );

  final StubContestRepository _contests;
  final StubScorePlaceholderRepository _placeholders;
  final StubScoreAttemptRepository _attempts;

  final List<OfficialScore> stored = [];

  @override
  Future<List<OfficialScore>> listForPlaceholder(Id scorePlaceholderId) async =>
      [
        for (final score in stored)
          if (score.scorePlaceholderId == scorePlaceholderId) score,
      ]..sort((a, b) => a.scoreRevision.compareTo(b.scoreRevision));

  @override
  Future<OfficialScore?> currentForPlaceholder(Id scorePlaceholderId) async =>
      (await listForPlaceholder(scorePlaceholderId)).lastOrNull;

  @override
  Future<RecordedScore> recordEntry(
    RecordedScore entry, {
    required MutationMetadata metadata,
  }) async {
    final placeholder = entry.placeholder;
    final index = _placeholders.stored.indexWhere(
      (p) => p.id == placeholder.id,
    );
    final current = _placeholders.stored[index];
    if (current.revision != placeholder.revision) {
      throw StaleRevisionError(
        entityType: 'ScorePlaceholder',
        entityId: placeholder.id,
        expectedRevision: placeholder.revision,
        storedRevision: current.revision,
      );
    }
    final contest = entry.contest;
    final savedContest = contest == null
        ? null
        : await _contests.save(contest, metadata: metadata);
    final savedPlaceholder = ScorePlaceholder.fromJson({
      ...placeholder.toJson(),
      'revision': current.revision + 1,
    });
    _placeholders.stored[index] = savedPlaceholder;
    _attempts.stored.add(entry.attempt);
    stored.add(entry.officialScore);
    return RecordedScore(
      attempt: entry.attempt,
      officialScore: entry.officialScore,
      placeholder: savedPlaceholder,
      contest: savedContest,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
