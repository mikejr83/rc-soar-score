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

  @override
  Future<void> replaceResultsForContest({
    required core.Id contestId,
    Iterable<core.FlightResult> flights = const [],
    Iterable<core.ParticipationStanding> standings = const [],
    Iterable<core.TeamStanding> teamStandings = const [],
  }) {
    final flightList = flights.toList();
    for (final flight in flightList) {
      if (flight.contestId != contestId) {
        throw ArgumentError('a FlightResult belongs to another contest');
      }
    }
    final standingList = standings.toList();
    for (final standing in standingList) {
      if (standing.contestId != contestId) {
        throw ArgumentError(
          'a ParticipationStanding belongs to another contest',
        );
      }
    }
    final teamList = teamStandings.toList();
    for (final team in teamList) {
      if (team.contestId != contestId) {
        throw ArgumentError('a TeamStanding belongs to another contest');
      }
    }

    final standingStore = store<core.ParticipationStanding>(
      'ParticipationStanding',
    );
    final teamStore = store<core.TeamStanding>('TeamStanding');

    return db.transaction(() async {
      await _store.removeWhereId('contest_id', contestId);
      await standingStore.removeWhereId('contest_id', contestId);
      await teamStore.removeWhereId('contest_id', contestId);

      for (final flight in flightList) {
        await _store.upsertJson(_store.encode(flight));
      }
      for (final standing in standingList) {
        await standingStore.upsertJson(standingStore.encode(standing));
      }
      for (final team in teamList) {
        await teamStore.upsertJson(teamStore.encode(team));
      }
    });
  }
}
