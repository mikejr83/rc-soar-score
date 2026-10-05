import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Official scores in the database; append-only.
class OfficialScoreRepository extends DriftRepository
    implements core.OfficialScoreRepository {
  OfficialScoreRepository(super.db, {super.stores});

  late final _store = store<core.OfficialScore>('OfficialScore');

  @override
  Future<core.OfficialScore?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.OfficialScore>> listForPlaceholder(
    core.Id scorePlaceholderId,
  ) => _store.whereId(
    'score_placeholder_id',
    scorePlaceholderId,
    orderBy: 'score_revision',
  );

  @override
  Future<core.OfficialScore?> currentForPlaceholder(
    core.Id scorePlaceholderId,
  ) async {
    final scores = await listForPlaceholder(scorePlaceholderId);
    return scores.isEmpty ? null : scores.last;
  }

  @override
  Future<core.OfficialScore> append(
    core.OfficialScore score, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.append(score, metadata: metadata));

  @override
  Future<core.OfficialScore> recordOfficial(
    core.OfficialScore score,
    core.ScorePlaceholder placeholder, {
    required core.MutationMetadata metadata,
  }) {
    if (placeholder.id != score.scorePlaceholderId) {
      throw ArgumentError('the placeholder is not the score\'s');
    }
    if (placeholder.scoreRevision != score.scoreRevision) {
      throw ArgumentError(
        'the placeholder carries score revision ${placeholder.scoreRevision}, '
        'the score is revision ${score.scoreRevision}',
      );
    }
    return unitOfWork.run((context) async {
      await context.append(score, metadata: metadata);
      await context.save(
        placeholder,
        metadata: metadata.forPart(placeholder.id.value),
      );
      return score;
    });
  }
}
