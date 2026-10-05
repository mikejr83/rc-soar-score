import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Rounds in the database.
class RoundRepository extends DriftRepository implements core.RoundRepository {
  RoundRepository(super.db, {super.stores});

  late final _store = store<core.Round>('Round');
  late final _groups = store<core.RoundGroup>('RoundGroup');

  @override
  Future<core.Round?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.Round>> listForRevision(core.Id matrixRevisionId) => _store
      .whereId('matrix_revision_id', matrixRevisionId, orderBy: 'ordinal, id');

  @override
  Future<List<core.Round>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'ordinal, id');

  @override
  Future<core.Round> save(
    core.Round round, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(round, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final round = await _store.find(id);
        if (round == null) return false;
        for (final group in await _groups.whereId('round_id', id)) {
          await context.delete(
            group,
            metadata: metadata.forPart(group.id.value),
          );
        }
        await context.delete(round, metadata: metadata);
        return true;
      });
}
