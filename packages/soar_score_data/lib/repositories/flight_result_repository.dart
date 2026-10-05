import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Flight results in the database; derived, so written without a mutation.
class FlightResultRepository extends DriftRepository
    implements core.FlightResultRepository {
  FlightResultRepository(super.db, {super.stores});

  late final _store = store<core.FlightResult>('FlightResult');

  @override
  Future<core.FlightResult?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.FlightResult?> findForPlaceholder(
    core.Id scorePlaceholderId,
  ) async {
    final found = await _store.whereId(
      'score_placeholder_id',
      scorePlaceholderId,
    );
    return found.isEmpty ? null : found.single;
  }

  @override
  Future<List<core.FlightResult>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.FlightResult>> listForParticipation(
    core.Id contestParticipationId,
  ) => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'id',
  );

  @override
  Future<void> replaceForContest(
    core.Id contestId,
    Iterable<core.FlightResult> results,
  ) => replaceRows(_store, contestId, results, (result) => result.contestId);
}
