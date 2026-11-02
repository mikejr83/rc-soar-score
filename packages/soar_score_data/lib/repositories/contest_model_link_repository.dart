import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Contest model links in the database.
class ContestModelLinkRepository extends DriftRepository
    implements core.ContestModelLinkRepository {
  ContestModelLinkRepository(super.db, {super.stores});

  late final _store = store<core.ContestModelLink>('ContestModelLink');

  @override
  Future<core.ContestModelLink?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ContestModelLink>> listForParticipation(
    core.Id contestParticipationId,
  ) => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'id',
  );

  @override
  Future<List<core.ContestModelLink>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<core.ContestModelLink> save(
    core.ContestModelLink link, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(link, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final link = await _store.find(id);
        if (link == null) return false;
        await context.delete(link, metadata: metadata);
        return true;
      });
}
