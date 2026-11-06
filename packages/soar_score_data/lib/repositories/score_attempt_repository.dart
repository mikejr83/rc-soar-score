import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Score attempts in the database; append-only.
class ScoreAttemptRepository extends DriftRepository
    implements core.ScoreAttemptRepository {
  ScoreAttemptRepository(super.db, {super.stores});

  late final _store = store<core.ScoreAttempt>('ScoreAttempt');

  @override
  Future<core.ScoreAttempt?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.ScoreAttempt?> findByClientMutationId(
    core.Id contestId,
    String clientMutationId,
  ) async {
    final found = await _store.whereId('contest_id', contestId);
    for (final attempt in found) {
      if (attempt.clientMutationId == clientMutationId) return attempt;
    }
    return null;
  }

  @override
  Future<List<core.ScoreAttempt>> listForPlaceholder(
    core.Id scorePlaceholderId,
  ) =>
      _store.whereId('score_placeholder_id', scorePlaceholderId, orderBy: 'id');

  @override
  Future<core.ScoreAttempt?> latestForPlaceholder(
    core.Id scorePlaceholderId,
  ) async {
    final attempts = await listForPlaceholder(scorePlaceholderId);
    return attempts.isEmpty ? null : attempts.last;
  }

  @override
  Future<Map<core.Id, core.ScoreAttempt>> latestForPlaceholders(
    Iterable<core.Id> scorePlaceholderIds,
  ) async {
    final attempts = await _store.whereIdIn(
      'score_placeholder_id',
      scorePlaceholderIds,
    );
    // Ids are time-ordered (UUIDv7), as in listForPlaceholder.
    attempts.sort((a, b) => a.id.value.compareTo(b.id.value));
    return {
      for (final attempt in attempts) attempt.scorePlaceholderId: attempt,
    };
  }

  @override
  Future<Map<core.Id, core.ScoreAttempt>> findByIds(
    Iterable<core.Id> ids,
  ) async => {
    for (final attempt in await _store.whereIdIn('id', ids))
      attempt.id: attempt,
  };

  @override
  Future<core.ScoreAttempt> append(
    core.ScoreAttempt attempt, {
    required core.MutationMetadata metadata,
  }) =>
      unitOfWork.run((context) => context.append(attempt, metadata: metadata));

  @override
  Future<core.ScoreAttempt> recordAttempt(
    core.ScoreAttempt attempt,
    core.ScorePlaceholder placeholder, {
    required core.MutationMetadata metadata,
  }) {
    if (placeholder.id != attempt.scorePlaceholderId) {
      throw ArgumentError('the placeholder is not the attempt\'s');
    }
    return unitOfWork.run((context) async {
      await context.append(attempt, metadata: metadata);
      await context.save(
        placeholder,
        metadata: metadata.forPart(placeholder.id.value),
      );
      return attempt;
    });
  }
}
