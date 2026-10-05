import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

TeamEntry team(String id, List<String> pilots) =>
    TeamEntry(teamId: id, pilotIds: pilots);

List<TeamPlace> rank(
  List<TeamEntry> teams,
  List<ContestTotal> totals, {
  int pilotCount = 2,
}) => rankTeams(teams, totals, rankPilots(totals), pilotCount: pilotCount);

Map<String, List<Object>> summary(List<TeamPlace> places) => {
  for (final p in places) p.teamId: [p.place, p.isTied, p.total],
};

void main() {
  group('team totals', () {
    test('sum the best N pilot scores', () {
      final totals = [
        pilotTotal('p1', 3000),
        pilotTotal('p2', 2900),
        pilotTotal('p3', 2000),
        pilotTotal('p4', 1900),
      ];

      final places = rank([
        team('red', ['p3', 'p1', 'p2']),
        team('blue', ['p4']),
      ], totals);

      expect(summary(places), {
        'red': [1, false, 5900.0],
        'blue': [2, false, 1900.0],
      });
      expect(places.first.countedPilotIds, ['p1', 'p2']);
    });

    test('a team with fewer pilots counts them all', () {
      final places = rank(
        [
          team('solo', ['p1']),
        ],
        [pilotTotal('p1', 3000)],
        pilotCount: 3,
      );

      expect(places.single.total, 3000);
      expect(places.single.countedPilotIds, ['p1']);
    });

    test('members with no total are skipped', () {
      final places = rank(
        [
          team('red', ['p1', 'ghost']),
        ],
        [pilotTotal('p1', 3000)],
      );

      expect(places.single.countedPilotIds, ['p1']);
    });

    test('sum without floating-point drift', () {
      final places = rank(
        [
          team('red', ['p1', 'p2']),
        ],
        [pilotTotal('p1', 0.1), pilotTotal('p2', 0.2)],
      );

      expect(places.single.total, 0.3);
    });

    test('are preliminary when a counted pilot is', () {
      final totals = [
        pilotTotal('p1', 3000),
        pilotTotal('p2', 2000, preliminary: true),
        pilotTotal('p3', 1000, preliminary: true),
      ];

      final places = rank(
        [
          team('red', ['p1', 'p2']),
          team('blue', ['p1', 'p2', 'p3']),
        ],
        totals,
        pilotCount: 1,
      );

      expect(places.map((p) => p.isPreliminary), [false, false]);
      expect(
        rank([
          team('red', ['p1', 'p2']),
        ], totals).single.isPreliminary,
        isTrue,
      );
    });
  });

  group('team tie-breakers', () {
    test('the lowest sum of counted pilot places wins', () {
      final totals = [
        pilotTotal('a1', 3000),
        pilotTotal('a2', 1000),
        pilotTotal('b1', 2500),
        pilotTotal('b2', 1500),
      ];

      // Both teams total 4000. Team a places: 1 + 4 = 5; team b: 2 + 3 = 5.
      // Equal sums, so the best individual place decides: a has 1.
      final tiedOnSum = rank([
        team('b', ['b1', 'b2']),
        team('a', ['a1', 'a2']),
      ], totals);
      expect(summary(tiedOnSum), {
        'a': [1, false, 4000.0],
        'b': [2, false, 4000.0],
      });

      final totals2 = [
        pilotTotal('a1', 2000),
        pilotTotal('a2', 2000),
        pilotTotal('b1', 3000),
        pilotTotal('b2', 1000),
      ];
      // Both total 4000. Team a places: 2 + 2 = 4; team b: 1 + 4 = 5.
      final bySum = rank([
        team('b', ['b1', 'b2']),
        team('a', ['a1', 'a2']),
      ], totals2);
      expect(summary(bySum), {
        'a': [1, false, 4000.0],
        'b': [2, false, 4000.0],
      });
    });

    test('teams level on every key share a place', () {
      final totals = [
        pilotTotal('a1', 2000),
        pilotTotal('b1', 2000),
        pilotTotal('c1', 500),
      ];

      final places = rank(
        [
          team('a', ['a1']),
          team('b', ['b1']),
          team('c', ['c1']),
        ],
        totals,
        pilotCount: 1,
      );

      expect(summary(places), {
        'a': [1, true, 2000.0],
        'b': [1, true, 2000.0],
        'c': [3, false, 500.0],
      });
    });

    test('a team with no flying pilots ranks last', () {
      final places = rank(
        [
          team('empty', ['ghost']),
          team('a', ['a1']),
        ],
        [pilotTotal('a1', 0)],
        pilotCount: 1,
      );

      expect(places.map((p) => p.teamId), ['a', 'empty']);
    });
  });

  group('invalid input', () {
    test('rejects a pilot count below one', () {
      expect(() => rank([], [], pilotCount: 0), throwsArgumentError);
    });

    test('rejects a team listed twice', () {
      expect(
        () => rank([
          team('a', ['p1']),
          team('a', ['p2']),
        ], []),
        throwsA(isA<ScoringValidationError>()),
      );
    });
  });
}
