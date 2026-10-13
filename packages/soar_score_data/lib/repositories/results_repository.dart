import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// The three derived results tables in one repository, so a recalculation
/// replaces them all in one transaction.
class ResultsRepository extends DriftRepository
    implements core.ResultsRepository {
  ResultsRepository(super.db, {super.stores});

  late final _flights = store<core.FlightResult>('FlightResult');
  late final _standings = store<core.ParticipationStanding>(
    'ParticipationStanding',
  );
  late final _teams = store<core.TeamStanding>('TeamStanding');

  @override
  Future<void> replaceResultsForContest(
    core.Id contestId,
    Iterable<core.FlightResult> flights,
    Iterable<core.ParticipationStanding> standings,
    Iterable<core.TeamStanding> teams,
  ) async {
    final flightRows = flights.toList();
    final standingRows = standings.toList();
    final teamRows = teams.toList();
    for (final row in flightRows) {
      if (row.contestId != contestId) {
        throw ArgumentError('a FlightResult belongs to another contest');
      }
    }
    for (final row in standingRows) {
      if (row.contestId != contestId) {
        throw ArgumentError(
          'a ParticipationStanding belongs to another contest',
        );
      }
    }
    for (final row in teamRows) {
      if (row.contestId != contestId) {
        throw ArgumentError('a TeamStanding belongs to another contest');
      }
    }
    await db.transaction(() async {
      await _flights.removeWhereId('contest_id', contestId);
      for (final row in flightRows) {
        await _flights.upsertJson(_flights.encode(row));
      }
      await _standings.removeWhereId('contest_id', contestId);
      for (final row in standingRows) {
        await _standings.upsertJson(_standings.encode(row));
      }
      await _teams.removeWhereId('contest_id', contestId);
      for (final row in teamRows) {
        await _teams.upsertJson(_teams.encode(row));
      }
    });
  }
}
