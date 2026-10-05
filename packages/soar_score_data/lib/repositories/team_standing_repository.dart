import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Team standings in the database; derived, so written without a mutation.
class TeamStandingRepository extends DriftRepository
    implements core.TeamStandingRepository {
  TeamStandingRepository(super.db, {super.stores});

  late final _store = store<core.TeamStanding>('TeamStanding');

  @override
  Future<core.TeamStanding?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.TeamStanding>> listForContest(core.Id contestId) => _store
      .whereId('contest_id', contestId, orderBy: 'as_of_round, place, id');

  @override
  Future<List<core.TeamStanding>> listAsOfRound(
    core.Id contestId,
    int asOfRound,
  ) async => [
    for (final standing in await listForContest(contestId))
      if (standing.asOfRound == asOfRound) standing,
  ];

  @override
  Future<List<core.TeamStanding>> listForTeam(core.Id teamId) =>
      _store.whereId('team_id', teamId, orderBy: 'as_of_round');

  @override
  Future<void> replaceForContest(
    core.Id contestId,
    Iterable<core.TeamStanding> standings,
  ) => replaceRows(
    _store,
    contestId,
    standings,
    (standing) => standing.contestId,
  );
}
