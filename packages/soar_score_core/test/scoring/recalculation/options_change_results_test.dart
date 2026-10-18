import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

/// Proves each Recalculating contest option (plan/data-model/contest-options.md)
/// changes the results, so an option that is stored but ignored fails here.

const noPenalty = <String, Object?>{'minor_penalty_per_meter': 0};

F5jFlightEntry flight(String id, num time) => F5jFlightEntry(
  pilotId: id,
  components: {'time_flown': time, 'launch_height': 1},
  landingBonus: 0,
);

/// Two pilots, two rounds. Pilot a wins round 1, b wins round 2, so their
/// normalized totals tie at 1500 while a has the higher raw total.
F5jContestInput tiedContest() => F5jContestInput(
  pilotIds: ['a', 'b'],
  rounds: [
    F5jRoundInput(
      round: 1,
      groups: [
        [flight('a', 500), flight('b', 250)],
      ],
    ),
    F5jRoundInput(
      round: 2,
      groups: [
        [flight('a', 200), flight('b', 400)],
      ],
    ),
  ],
);

/// Three pilots of one team and one outsider flying a single group.
F5jContestInput teamContest() => F5jContestInput(
  pilotIds: ['a', 'b', 'c', 'x'],
  rounds: [
    F5jRoundInput(
      round: 1,
      groups: [
        [
          flight('a', 500),
          flight('b', 400),
          flight('c', 300),
          flight('x', 450),
        ],
      ],
    ),
  ],
  teams: [
    TeamEntry(teamId: 't', pilotIds: ['a', 'b', 'c']),
    TeamEntry(teamId: 'u', pilotIds: ['x']),
  ],
);

F5jStanding last(
  F5jContestInput input, {
  Map<String, Object?> options = const {},
  int completedRounds = 2,
  List<int> dropAfterRounds = const [],
  bool tieBreakerEnabled = false,
  int? teamPilotCount,
}) => recalculateF5jContest(
  input,
  options: {...noPenalty, ...options},
  completedRounds: completedRounds,
  dropAfterRounds: dropAfterRounds,
  tieBreakerEnabled: tieBreakerEnabled,
  teamPilotCount: teamPilotCount,
).standings.last;

List<double> scores(F5jStanding s) => [
  for (final t in s.totals) t.overallScore,
];

void main() {
  test('group_score_mode changes the standings', () {
    final normalized = last(tiedContest());
    final raw = last(tiedContest(), options: {'group_score_mode': 'Raw'});
    expect(scores(normalized), [1500, 1500]);
    expect(scores(raw), [700, 650]);
  });

  test('rounding_mode changes the group scores', () {
    // 250 / 500 and 400 / 400 are exact; use a ratio that does not divide.
    final input = F5jContestInput(
      pilotIds: ['a', 'b'],
      rounds: [
        F5jRoundInput(
          round: 1,
          groups: [
            [flight('a', 550), flight('b', 500)],
          ],
        ),
      ],
    );
    final rounded = last(input, completedRounds: 1);
    final truncated = last(
      input,
      completedRounds: 1,
      options: {'rounding_mode': 'Truncate'},
    );
    expect(scores(rounded), [1000, 909.1]);
    expect(scores(truncated), [1000, 909.0]);
  });

  test('decimal_places changes the group scores', () {
    final input = F5jContestInput(
      pilotIds: ['a', 'b'],
      rounds: [
        F5jRoundInput(
          round: 1,
          groups: [
            [flight('a', 550), flight('b', 500)],
          ],
        ),
      ],
    );
    expect(
      scores(last(input, completedRounds: 1, options: {'decimal_places': 0})),
      [1000, 909],
    );
    expect(
      scores(last(input, completedRounds: 1, options: {'decimal_places': 2})),
      [1000, 909.09],
    );
  });

  test('drop_after_rounds changes the standings', () {
    final without = last(tiedContest());
    final dropped = last(tiedContest(), dropAfterRounds: [2]);
    expect(scores(without), [1500, 1500]);
    expect(scores(dropped), [1000, 1000]);
    expect(dropped.totals.first.droppedRounds, isNotEmpty);
  });

  test('tiebreaker_enabled breaks a tie on raw points', () {
    final off = last(tiedContest());
    final on = last(tiedContest(), tieBreakerEnabled: true);
    expect(off.ranking.placeOf('a')!.place, 1);
    expect(off.ranking.placeOf('b')!.place, 1);
    expect(off.ranking.placeOf('a')!.isTied, isTrue);
    expect(on.ranking.placeOf('a')!.place, 1);
    expect(on.ranking.placeOf('b')!.place, 2);
    expect(on.ranking.placeOf('b')!.isTied, isFalse);
  });

  test('team_pilot_count changes the team totals', () {
    final one = last(teamContest(), completedRounds: 1, teamPilotCount: 1);
    final two = last(teamContest(), completedRounds: 1, teamPilotCount: 2);
    double totalOf(F5jStanding s, String team) =>
        s.teams.firstWhere((t) => t.teamId == team).total;
    expect(totalOf(one, 't'), 1000);
    expect(totalOf(two, 't'), 1000 + 800);
    expect(totalOf(one, 't'), isNot(totalOf(two, 't')));
  });

  test('without team_pilot_count no team standings are produced', () {
    expect(last(teamContest(), completedRounds: 1).teams, isEmpty);
  });
}
