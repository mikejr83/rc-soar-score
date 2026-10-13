import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

DrawPilot _pilot(int n, {int? team}) =>
    DrawPilot(_id(n), teamId: team == null ? null : _id(1000 + team));

/// One round of the given groups, each a list of pilot numbers.
List<List<DrawSlot>> _round(List<List<int>> groups, {Map<int, int>? teams}) => [
  for (final group in groups)
    [for (final n in group) DrawSlot(_pilot(n, team: teams?[n]), null)],
];

void main() {
  test('counts meetings, never-met pairs and the histogram', () {
    // Pilots 1 to 4: 1-2 and 3-4 meet twice, the other four pairs never.
    final rounds = [
      _round([
        [1, 2],
        [3, 4],
      ]),
      _round([
        [1, 2],
        [3, 4],
      ]),
    ];

    final stats = MatchupStats.of(rounds, teamProtection: false);

    expect(stats.feasiblePairs, 6);
    expect(stats.unmet, 4);
    expect(stats.maxDuplicates, 2);
    expect(stats.histogram, {0: 4, 2: 2});
    expect(stats.sumSquares, 8);
    expect(stats.totalMeetings, 4);
  });

  test('cost is the squared deviation from the mean over feasible pairs', () {
    final rounds = [
      _round([
        [1, 2],
        [3, 4],
      ]),
    ];

    final stats = MatchupStats.of(rounds, teamProtection: false);

    // Two pairs met once, four never; mean 1/3.
    expect(stats.mean, closeTo(1 / 3, 1e-12));
    expect(stats.cost, closeTo(2 * (2 / 3) * (2 / 3) + 4 * (1 / 9), 1e-9));
  });

  test('the best possible cost follows the whole-number limit', () {
    final rounds = [
      _round([
        [1, 2],
        [3, 4],
      ]),
    ];

    final stats = MatchupStats.of(rounds, teamProtection: false);

    // f = 1/3: six pairs, 6 * f * (1 - f) = 4/3, which is also the cost here.
    expect(stats.idealCost, closeTo(4 / 3, 1e-9));
    expect(stats.cost, closeTo(stats.idealCost, 1e-9));
  });

  test('teammates are not feasible pairs under team protection', () {
    final teams = {1: 1, 2: 1, 3: 2, 4: 2};
    final rounds = [
      _round([
        [1, 3],
        [2, 4],
      ], teams: teams),
    ];

    final stats = MatchupStats.of(rounds, teamProtection: true);

    expect(stats.feasiblePairs, 4);
    expect(stats.unmet, 2);
    expect(stats.histogram, {0: 2, 1: 2});
  });

  test('compares by never-met pairs, then repeats, then squares', () {
    MatchupStats of(List<List<List<int>>> groupsPerRound) => MatchupStats.of([
      for (final groups in groupsPerRound) _round(groups),
    ], teamProtection: false);

    final fewerUnmet = of([
      [
        [1, 2, 3],
        [4],
      ],
      [
        [1, 4],
        [2, 3],
      ],
    ]);
    final moreUnmet = of([
      [
        [1, 2],
        [3, 4],
      ],
      [
        [1, 2],
        [3, 4],
      ],
    ]);
    expect(fewerUnmet.unmet, lessThan(moreUnmet.unmet));
    expect(fewerUnmet.compareQuality(moreUnmet), lessThan(0));
    expect(moreUnmet.compareQuality(fewerUnmet), greaterThan(0));
    expect(fewerUnmet.compareQuality(fewerUnmet), 0);
  });
}
