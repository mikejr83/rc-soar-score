import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

/// A launch height of 1 m costs nothing when the penalty per meter is zero.
const noPenalty = <String, Object?>{'minor_penalty_per_meter': 0};

F5jFlightEntry flight(String id, num time, double bonus) => F5jFlightEntry(
  pilotId: id,
  components: {'time_flown': time, 'launch_height': 1},
  landingBonus: bonus,
);

F5jContestInput contest({num aRound2 = 300}) => F5jContestInput(
  pilotIds: ['a', 'b'],
  rounds: [
    F5jRoundInput(
      round: 1,
      groups: [
        [flight('a', 500, 50), flight('b', 400, 100)],
      ],
    ),
    F5jRoundInput(
      round: 2,
      groups: [
        [flight('a', aRound2, 0), flight('b', 450, 50)],
      ],
    ),
  ],
);

F5jRecalculation run(
  F5jContestInput input, {
  Map<String, Object?> options = noPenalty,
  RecalculationScope? scope,
}) => recalculateF5jContest(
  input,
  options: options,
  completedRounds: 2,
  scope: scope,
);

void main() {
  test('runs the whole pipeline on a two round contest', () {
    final result = run(contest());

    // Round 1: a 550 raw, b 500 raw -> 1000 and 909.1. Round 2: a 300, b 500.
    final groupScores = {
      for (final f in result.flights) (f.round, f.pilotId): f.group.groupScore,
    };
    expect(groupScores[(1, 'a')], 1000);
    expect(groupScores[(1, 'b')], 909.1);
    expect(groupScores[(2, 'a')], 600);
    expect(groupScores[(2, 'b')], 1000);

    expect(result.calculationVersion, f5jCalculationVersion);
    expect(result.standings.map((s) => s.asOfRound), [1, 2]);
    final first = result.standings[0].ranking;
    expect(first.placeOf('a')!.place, 1);
    final last = result.standings[1];
    expect(last.totals.map((t) => t.overallScore), [1600, 1909.1]);
    expect(last.ranking.placeOf('b')!.place, 1);
    expect(last.ranking.placeOf('a')!.place, 2);
    expect(last.totals.every((t) => !t.isPreliminary), isTrue);
  });

  test('the same input always gives the same result', () {
    expect(run(contest()), run(contest()));
  });

  test('a changed score from round 2 keeps round 1 untouched', () {
    final before = run(contest());
    final after = run(
      contest(aRound2: 500),
      scope: RecalculationScope.forScoreChange(2),
    );
    expect(after.fromRound, 2);
    expect(after.flights.map((f) => f.round).toSet(), {2});
    expect(after.standings.map((s) => s.asOfRound), [2]);
    expect(after.standings.single.totals.map((t) => t.overallScore), [
      2000,
      1909.1,
    ]);
    expect(
      after.standings.single.totals.map((t) => t.overallScore),
      isNot(before.standings.last.totals.map((t) => t.overallScore)),
    );
  });

  test('a scoped run equals the tail of a full run', () {
    final full = run(contest());
    final scoped = run(contest(), scope: RecalculationScope.forScoreChange(2));
    expect(scoped.standings, [full.standings.last]);
    expect(scoped.flights, full.flights.where((f) => f.round == 2).toList());
  });

  test('a recalculating option change gives the recomputed results', () {
    final raw = run(
      contest(),
      options: {...noPenalty, 'group_score_mode': 'Raw'},
    );
    final scores = {
      for (final f in raw.flights) (f.round, f.pilotId): f.group.groupScore,
    };
    expect(scores[(1, 'a')], 550);
    expect(scores[(1, 'b')], 500);
    expect(raw.standings.last.totals.map((t) => t.overallScore), [850, 1000]);
  });

  test('a pilot who has not flown a round is preliminary', () {
    final input = F5jContestInput(
      pilotIds: ['a', 'b'],
      rounds: [
        F5jRoundInput(
          round: 1,
          groups: [
            [flight('a', 500, 0)],
          ],
        ),
      ],
    );
    final totals = recalculateF5jContest(
      input,
      options: noPenalty,
      completedRounds: 1,
    ).standings.single.totals;
    expect(totals.firstWhere((t) => t.pilotId == 'a').isPreliminary, isFalse);
    expect(totals.firstWhere((t) => t.pilotId == 'b').isPreliminary, isTrue);
    expect(totals.firstWhere((t) => t.pilotId == 'b').overallScore, 0);
  });

  test('drops and teams run through the pipeline', () {
    final result = recalculateF5jContest(
      F5jContestInput(
        pilotIds: ['a', 'b'],
        rounds: contest().rounds,
        teams: [
          TeamEntry(teamId: 't', pilotIds: ['a', 'b']),
        ],
      ),
      options: noPenalty,
      completedRounds: 2,
      dropAfterRounds: [2],
      teamPilotCount: 2,
    );
    final standing = result.standings.last;
    expect(standing.totals.first.droppedRounds, [2]);
    expect(standing.totals.first.overallScore, 1000);
    expect(standing.teams.single.total, 1000 + 1000);
  });

  test('an unknown pilot in a group is rejected', () {
    expect(
      () => recalculateF5jContest(
        F5jContestInput(
          pilotIds: ['a'],
          rounds: [
            F5jRoundInput(
              round: 1,
              groups: [
                [flight('a', 500, 0), flight('x', 400, 0)],
              ],
            ),
          ],
        ),
        options: noPenalty,
        completedRounds: 1,
      ),
      throwsArgumentError,
    );
  });

  test('invalid components fail the whole recalculation', () {
    expect(
      () => recalculateF5jContest(
        F5jContestInput(
          pilotIds: ['a'],
          rounds: [
            F5jRoundInput(
              round: 1,
              groups: [
                [flight('a', -5, 0)],
              ],
            ),
          ],
        ),
        options: noPenalty,
        completedRounds: 1,
      ),
      throwsA(isA<ScoringValidationError>()),
    );
  });
}
