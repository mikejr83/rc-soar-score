import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Score placeholders in the database.
class ScorePlaceholderRepository extends DriftRepository
    implements core.ScorePlaceholderRepository {
  ScorePlaceholderRepository(super.db, {super.stores});

  late final _store = store<core.ScorePlaceholder>('ScorePlaceholder');

  @override
  Future<core.ScorePlaceholder?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.ScorePlaceholder?> findForAssignment(core.Id assignmentId) async {
    final found = await _store.whereId('assignment_id', assignmentId);
    return found.isEmpty ? null : found.single;
  }

  @override
  Future<List<core.ScorePlaceholder>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.ScorePlaceholder>> listForParticipation(
    core.Id contestParticipationId,
  ) => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'id',
  );

  @override
  Future<core.ScorePlaceholder> save(
    core.ScorePlaceholder placeholder, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run(
    (context) => context.save(placeholder, metadata: metadata),
  );

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final placeholder = await _store.find(id);
        if (placeholder == null) return false;
        await context.delete(placeholder, metadata: metadata);
        return true;
      });
}
