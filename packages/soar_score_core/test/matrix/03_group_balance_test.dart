import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Group Balance', () {
    late MatrixDrawService service;

    setUp(() {
      service = MatrixDrawService(seed: 42);
    });

    test('exact division - 8 pilots, 4 groups, 1 round', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
        pilotTeams: {},
        groupsPerRound: 4,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      // All groups should have exactly 2 pilots
      for (final group in result.rounds[0].groups) {
        expect(group.length, 2);
      }
    });

    test('remainder distribution - 10 pilots, 3 groups, 1 round', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9', 'p10'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      // Group sizes should be 4, 3, 3
      final groupSizes = result.rounds[0].groups
          .map((g) => g.length)
          .toList()
        ..sort();
      expect(groupSizes, [3, 3, 4]);

      // All 10 pilots assigned
      final allPilots = <String>{};
      for (final group in result.rounds[0].groups) {
        for (final a in group) {
          allPilots.add(a.pilotId);
        }
      }
      expect(allPilots.length, 10);
    });

    test('larger uneven case - 15 pilots, 4 groups, 1 round', () {
      final pilotIds = List.generate(15, (i) => 'p${i + 1}');
      final result = service.generate(
        pilotIds: pilotIds,
        pilotTeams: {},
        groupsPerRound: 4,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      // Group sizes should be 4, 4, 4, 3
      final groupSizes = result.rounds[0].groups
          .map((g) => g.length)
          .toList()
        ..sort();
      expect(groupSizes, [3, 4, 4, 4]);

      // All 15 pilots assigned
      final allPilots = <String>{};
      for (final group in result.rounds[0].groups) {
        for (final a in group) {
          allPilots.add(a.pilotId);
        }
      }
      expect(allPilots.length, 15);
    });

    test('group size difference at most 1 - 13 pilots, 5 groups', () {
      final pilotIds = List.generate(13, (i) => 'p${i + 1}');
      final result = service.generate(
        pilotIds: pilotIds,
        pilotTeams: {},
        groupsPerRound: 5,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      final groupSizes = result.rounds[0].groups.map((g) => g.length).toList();
      final maxSize = groupSizes.reduce((a, b) => a > b ? a : b);
      final minSize = groupSizes.reduce((a, b) => a < b ? a : b);
      expect(maxSize - minSize, lessThanOrEqualTo(1));
    });
  });
}
