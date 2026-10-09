import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Re-flights in the database.
class ReFlightRepository extends DriftRepository
    implements core.ReFlightRepository {
  ReFlightRepository(super.db, {super.stores});

  late final _store = store<core.ReFlight>('ReFlight');

  @override
  Future<core.ReFlight?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ReFlight>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.ReFlight>> listForSourceGroup(
    core.Id sourceRoundId,
    int sourceGroup,
  ) async {
    final found = await _store.whereId('source_round_id', sourceRoundId);
    return found.where((r) => r.sourceGroup == sourceGroup).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }

  @override
  Future<List<core.ReFlight>> listForScheduledRound(core.Id scheduledRoundId) =>
      _store.whereId('scheduled_round_id', scheduledRoundId, orderBy: 'id');

  @override
  Future<core.ReFlight> save(
    core.ReFlight reFlight, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(reFlight, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final reFlight = await _store.find(id);
        if (reFlight == null) return false;
        await context.delete(reFlight, metadata: metadata);
        return true;
      });
}
