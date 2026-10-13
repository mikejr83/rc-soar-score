import 'package:soar_score_core/soar_score_core.dart';

/// Flight results in memory, replaced per contest like the real repository.
class StubFlightResultRepository implements FlightResultRepository {
  final List<FlightResult> stored = [];

  @override
  Future<List<FlightResult>> listForContest(Id contestId) async => [
    for (final result in stored)
      if (result.contestId == contestId) result,
  ];

  @override
  Future<void> replaceForContest(
    Id contestId,
    Iterable<FlightResult> results,
  ) async {
    stored
      ..removeWhere((result) => result.contestId == contestId)
      ..addAll(results);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Pilot standings in memory, replaced per contest.
class StubParticipationStandingRepository
    implements ParticipationStandingRepository {
  final List<ParticipationStanding> stored = [];

  @override
  Future<List<ParticipationStanding>> listForContest(Id contestId) async => [
    for (final standing in stored)
      if (standing.contestId == contestId) standing,
  ];

  @override
  Future<void> replaceForContest(
    Id contestId,
    Iterable<ParticipationStanding> standings,
  ) async {
    stored
      ..removeWhere((standing) => standing.contestId == contestId)
      ..addAll(standings);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Team standings in memory, replaced per contest.
class StubTeamStandingRepository implements TeamStandingRepository {
  final List<TeamStanding> stored = [];

  @override
  Future<List<TeamStanding>> listForContest(Id contestId) async => [
    for (final standing in stored)
      if (standing.contestId == contestId) standing,
  ];

  @override
  Future<List<TeamStanding>> listAsOfRound(
    Id contestId,
    int asOfRound,
  ) async => [
    for (final standing in stored)
      if (standing.contestId == contestId && standing.asOfRound == asOfRound)
        standing,
  ];

  @override
  Future<void> replaceForContest(
    Id contestId,
    Iterable<TeamStanding> standings,
  ) async {
    stored
      ..removeWhere((standing) => standing.contestId == contestId)
      ..addAll(standings);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// The three result tables in memory, replaced together like the real
/// repository: one contest, all tables, one step.
class StubResultsRepository implements ResultsRepository {
  StubResultsRepository(
    this.flightResults,
    this.participationStandings,
    this.teamStandings,
  );

  final StubFlightResultRepository flightResults;
  final StubParticipationStandingRepository participationStandings;
  final StubTeamStandingRepository teamStandings;

  @override
  Future<void> replaceResultsForContest(
    Id contestId,
    Iterable<FlightResult> flights,
    Iterable<ParticipationStanding> standings,
    Iterable<TeamStanding> teams,
  ) async {
    for (final row in flights) {
      if (row.contestId != contestId) {
        throw ArgumentError('a FlightResult belongs to another contest');
      }
    }
    for (final row in standings) {
      if (row.contestId != contestId) {
        throw ArgumentError(
          'a ParticipationStanding belongs to another contest',
        );
      }
    }
    for (final row in teams) {
      if (row.contestId != contestId) {
        throw ArgumentError('a TeamStanding belongs to another contest');
      }
    }
    flightResults.stored
      ..removeWhere((row) => row.contestId == contestId)
      ..addAll(flights);
    participationStandings.stored
      ..removeWhere((row) => row.contestId == contestId)
      ..addAll(standings);
    teamStandings.stored
      ..removeWhere((row) => row.contestId == contestId)
      ..addAll(teams);
  }
}
