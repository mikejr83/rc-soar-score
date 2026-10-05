import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Round groups in the database.
class RoundGroupRepository extends DriftRepository
    implements core.RoundGroupRepository {
  RoundGroupRepository(super.db, {super.stores});

  late final _store = store<core.RoundGroup>('RoundGroup');

  @override
  Future<core.RoundGroup?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.RoundGroup>> listForRound(core.Id roundId) =>
      _store.whereId('round_id', roundId, orderBy: 'group_number, id');

  @override
  Future<List<core.RoundGroup>> listForContest(core.Id contestId) => _store
      .whereId('contest_id', contestId, orderBy: 'round_id, group_number');

  @override
  Future<core.RoundGroup> save(
    core.RoundGroup group, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(group, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final group = await _store.find(id);
        if (group == null) return false;
        await context.delete(group, metadata: metadata);
        return true;
      });
}
