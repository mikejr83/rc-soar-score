import '../../errors/scoring_validation_error.dart';
import '../f5j/f5j_profile.dart';
import '../group/group_score_calculator.dart';
import '../standings/rank_pilots.dart';
import '../standings/rank_teams.dart';
import '../totals/contest_total_calculator.dart';
import '../totals/contest_total_options.dart';
import '../totals/pilot_rounds.dart';
import '../totals/round_score.dart';
import 'calculation_version.dart';
import 'f5j_contest_input.dart';
import 'f5j_recalculation.dart';
import 'recalculation_scope.dart';

/// Recomputes the F5J results of a contest from its official data.
///
/// The pipeline is the one in `plan/architecture-requirements/
/// discipline-scoring.md`: flights, group scores, contest totals with drops
/// and penalties, then pilot and team places. The same input always gives the
/// same output. Flights are recomputed for rounds from `scope.fromRound`, and
/// a standing is produced for every completed round from there on, because a
/// changed score moves every later total. Totals still read the earlier
/// rounds, so they are computed from the raw data and never from stored
/// results.
///
/// [options] is the resolved profile and core options (for example
/// `group_score_mode`, `rounding_mode`, `working_time`). [completedRounds] is
/// the last round whose standing is produced.
///
/// Throws [ScoringValidationError] when an entry's components are invalid.
F5jRecalculation recalculateF5jContest(
  F5jContestInput input, {
  required Map<String, Object?> options,
  required int completedRounds,
  List<int> dropAfterRounds = const [],
  bool tieBreakerEnabled = false,
  int? teamPilotCount,
  RecalculationScope? scope,
}) {
  final fromRound = scope?.fromRound ?? 1;
  if (completedRounds < 0) {
    throw ArgumentError.value(completedRounds, 'completedRounds');
  }
  final profile = F5jProfile();
  final groupOptions = profile.options(options).groupScore;

  final scoresByPilot = {for (final id in input.pilotIds) id: <RoundScore>[]};
  final flights = <F5jRoundFlight>[];

  final rounds = [...input.rounds]..sort((a, b) => a.round.compareTo(b.round));
  for (final round in rounds) {
    for (final group in round.groups) {
      final results = [
        for (final entry in group)
          profile.calculate(
            entry.components,
            overrides: options,
            landingBonus: entry.landingBonus,
          ),
      ];
      final entries = calculateGroupScores([
        for (var i = 0; i < group.length; i++)
          results[i].toPilotRound(group[i].pilotId, retired: group[i].retired),
      ], groupOptions);
      for (var i = 0; i < group.length; i++) {
        final pilotId = group[i].pilotId;
        final scores = scoresByPilot[pilotId];
        if (scores == null) {
          throw ArgumentError.value(pilotId, 'pilotId', 'is not a pilot');
        }
        scores.add(
          RoundScore(
            round: round.round,
            groupScore: entries[i].groupScore,
            rawScore: results[i].rawScore,
            nonDroppable: results[i].nonDroppable,
            cumulativePenalty: group[i].cumulativePenalty,
            underReview: group[i].underReview,
          ),
        );
        if (round.round >= fromRound) {
          flights.add(
            F5jRoundFlight(
              round: round.round,
              pilotId: pilotId,
              flight: results[i],
              group: entries[i],
            ),
          );
        }
      }
    }
  }

  final pilots = [
    for (final id in input.pilotIds)
      PilotRounds(
        pilotId: id,
        scores: scoresByPilot[id]!,
        retiredAtRound: input.retiredAtRound[id],
      ),
  ];
  final totalOptions = ContestTotalOptions(dropAfterRounds: dropAfterRounds);

  final standings = <F5jStanding>[];
  for (var asOf = fromRound; asOf <= completedRounds; asOf++) {
    final totals = [
      for (final pilot in pilots)
        calculateContestTotal(pilot, asOfRound: asOf, options: totalOptions),
    ];
    final ranking = rankPilots(totals, tieBreakerEnabled: tieBreakerEnabled);
    standings.add(
      F5jStanding(
        asOfRound: asOf,
        totals: totals,
        ranking: ranking,
        teams: teamPilotCount == null || input.teams.isEmpty
            ? const []
            : rankTeams(
                input.teams,
                totals,
                ranking,
                pilotCount: teamPilotCount,
              ),
      ),
    );
  }

  return F5jRecalculation(
    calculationVersion: f5jCalculationVersion,
    fromRound: fromRound,
    flights: flights,
    standings: standings,
  );
}
