import 'package:equatable/equatable.dart';

import '../f5j/f5j_flight_result.dart';
import '../group/group_score_entry.dart';
import '../standings/pilot_ranking.dart';
import '../standings/team_place.dart';
import '../totals/contest_total.dart';

/// One recomputed flight with its group score.
class F5jRoundFlight extends Equatable {
  const F5jRoundFlight({
    required this.round,
    required this.pilotId,
    required this.flight,
    required this.group,
  });

  final int round;
  final String pilotId;
  final F5jFlightResult flight;
  final GroupScoreEntry group;

  @override
  List<Object?> get props => [round, pilotId, flight, group];
}

/// The standings as of one completed round.
class F5jStanding extends Equatable {
  F5jStanding({
    required this.asOfRound,
    required List<ContestTotal> totals,
    required this.ranking,
    required List<TeamPlace> teams,
  }) : totals = List.unmodifiable(totals),
       teams = List.unmodifiable(teams);

  final int asOfRound;
  final List<ContestTotal> totals;
  final PilotRanking ranking;
  final List<TeamPlace> teams;

  @override
  List<Object?> get props => [asOfRound, totals, ranking, teams];
}

/// The derived results of a recalculation from [fromRound] onward.
///
/// The data layer stamps these with the configuration and matrix revisions
/// they were computed under; [calculationVersion] is stamped here.
class F5jRecalculation extends Equatable {
  F5jRecalculation({
    required this.calculationVersion,
    required this.fromRound,
    required List<F5jRoundFlight> flights,
    required List<F5jStanding> standings,
  }) : flights = List.unmodifiable(flights),
       standings = List.unmodifiable(standings);

  final String calculationVersion;
  final int fromRound;

  /// Flights of every round from [fromRound] on, by round, group and pilot.
  final List<F5jRoundFlight> flights;

  /// One standing per completed round from [fromRound] on.
  final List<F5jStanding> standings;

  @override
  List<Object?> get props => [
    calculationVersion,
    fromRound,
    flights,
    standings,
  ];
}
