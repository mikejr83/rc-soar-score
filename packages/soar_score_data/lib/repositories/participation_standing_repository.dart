import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Participation standings in the database; derived, so written without a
/// mutation.
class ParticipationStandingRepository extends DriftRepository
    implements core.ParticipationStandingRepository {
  ParticipationStandingRepository(super.db, {super.stores});

  late final _store = store<core.ParticipationStanding>(
    'ParticipationStanding',
  );

  @override
  Future<core.ParticipationStanding?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ParticipationStanding>> listForContest(core.Id contestId) =>
      _store.whereId(
        'contest_id',
        contestId,
        orderBy: 'as_of_round, place, id',
      );

  @override
  Future<List<core.ParticipationStanding>> listAsOfRound(
    core.Id contestId,
    int asOfRound,
  ) async => [
    for (final standing in await listForContest(contestId))
      if (standing.asOfRound == asOfRound) standing,
  ];

  @override
  Future<List<core.ParticipationStanding>> listForParticipation(
    core.Id contestParticipationId,
  ) => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'as_of_round',
  );

  @override
  Future<void> replaceForContest(
    core.Id contestId,
    Iterable<core.ParticipationStanding> standings,
  ) => replaceRows(
    _store,
    contestId,
    standings,
    (standing) => standing.contestId,
  );
}
