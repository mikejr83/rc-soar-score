import '../../enums/lane_mode.dart';
import '../../models/id.dart';
import 'seeded_random.dart';

/// One pilot in a draw: the participation and the team it is on, if any.
class DrawPilot {
  const DrawPilot(this.participationId, {this.teamId});

  final Id participationId;
  final Id? teamId;
}

/// One pilot's place in a drawn group.
class DrawSlot {
  const DrawSlot(this.pilot, this.lane);

  final DrawPilot pilot;

  /// The lane, 1 to the group size, or `null` when the lane mode is `None`.
  final int? lane;
}

/// The simple draw behind the first matrix API: balanced groups, teammates
/// kept apart, no optimization of who meets whom.
///
/// Every round deals the pilots into [groupsPerRound] groups whose sizes
/// differ by at most one. The optimizer (`matrix-draw.md`) replaces the
/// dealing later; the inputs, the seed and the output shape stay the same.
class BasicDraw {
  const BasicDraw();

  /// How many times a round is dealt again when a deal leaves a pilot
  /// without a group free of teammates.
  static const int _attempts = 200;

  /// The groups of each of [rounds] rounds: `result[round][group]` lists the
  /// slots of that group, with lanes when [laneMode] is `random`.
  ///
  /// With [teamProtection], no two pilots of a team share a group; that needs
  /// at least as many groups as the largest team ([ArgumentError] otherwise).
  /// Throws an [ArgumentError] when the settings cannot be met.
  List<List<List<DrawSlot>>> generate({
    required List<DrawPilot> pilots,
    required int rounds,
    required int groupsPerRound,
    required bool teamProtection,
    required LaneMode laneMode,
    required SeededRandom random,
  }) {
    if (rounds < 1) {
      throw ArgumentError.value(rounds, 'rounds', 'must be at least 1');
    }
    if (groupsPerRound < 1 || groupsPerRound > pilots.length) {
      throw ArgumentError.value(
        groupsPerRound,
        'groupsPerRound',
        'must be between 1 and the number of pilots (${pilots.length})',
      );
    }
    if (teamProtection) {
      final largest = largestTeam(pilots);
      if (groupsPerRound < largest) {
        throw ArgumentError.value(
          groupsPerRound,
          'groupsPerRound',
          'team protection needs at least $largest groups, one for each '
              'pilot of the largest team',
        );
      }
    }
    return [
      for (var round = 0; round < rounds; round++)
        _round(pilots, groupsPerRound, teamProtection, laneMode, random),
    ];
  }

  /// The most pilots any one team has among [pilots].
  static int largestTeam(List<DrawPilot> pilots) {
    final sizes = <Id, int>{};
    for (final pilot in pilots) {
      final team = pilot.teamId;
      if (team != null) {
        sizes[team] = (sizes[team] ?? 0) + 1;
      }
    }
    return sizes.values.fold(0, (a, b) => a > b ? a : b);
  }

  List<List<DrawSlot>> _round(
    List<DrawPilot> pilots,
    int groupCount,
    bool teamProtection,
    LaneMode laneMode,
    SeededRandom random,
  ) {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final groups = _deal(pilots, groupCount, teamProtection, random);
      if (groups != null) {
        return [
          for (final group in groups) _withLanes(group, laneMode, random),
        ];
      }
    }
    throw ArgumentError(
      'no draw keeps every team apart with $groupCount groups; use more '
      'groups',
    );
  }

  /// One dealing of [pilots] into balanced groups, or `null` when it left a
  /// pilot with no group free of teammates.
  List<List<DrawPilot>>? _deal(
    List<DrawPilot> pilots,
    int groupCount,
    bool teamProtection,
    SeededRandom random,
  ) {
    final base = pilots.length ~/ groupCount;
    final extra = pilots.length % groupCount;
    // Which groups take the extra pilot differs from round to round.
    final order = random.shuffle([for (var g = 0; g < groupCount; g++) g]);
    final capacity = List<int>.filled(groupCount, base);
    for (var i = 0; i < extra; i++) {
      capacity[order[i]]++;
    }

    final teamSizes = <Id, int>{};
    for (final pilot in pilots) {
      final team = pilot.teamId;
      if (team != null) {
        teamSizes[team] = (teamSizes[team] ?? 0) + 1;
      }
    }
    // Shuffle, then place the biggest teams first so they get distinct
    // groups while there is still room (the sort is stable).
    final queue = random.shuffle([...pilots]);
    int size(DrawPilot p) => p.teamId == null ? 0 : teamSizes[p.teamId]!;
    final indexed = [for (var i = 0; i < queue.length; i++) (i, queue[i])]
      ..sort((a, b) {
        final bySize = size(b.$2).compareTo(size(a.$2));
        return bySize != 0 ? bySize : a.$1.compareTo(b.$1);
      });

    final groups = [for (var g = 0; g < groupCount; g++) <DrawPilot>[]];
    final teamsIn = [for (var g = 0; g < groupCount; g++) <Id>{}];
    for (final (_, pilot) in indexed) {
      final team = pilot.teamId;
      var bestFree = 0;
      final candidates = <int>[];
      for (var g = 0; g < groupCount; g++) {
        final free = capacity[g] - groups[g].length;
        if (free <= 0 ||
            (teamProtection && team != null && teamsIn[g].contains(team))) {
          continue;
        }
        if (free > bestFree) {
          bestFree = free;
          candidates
            ..clear()
            ..add(g);
        } else if (free == bestFree) {
          candidates.add(g);
        }
      }
      if (candidates.isEmpty) {
        return null;
      }
      final chosen = candidates[random.nextInt(candidates.length)];
      groups[chosen].add(pilot);
      if (team != null) {
        teamsIn[chosen].add(team);
      }
    }
    return groups;
  }

  List<DrawSlot> _withLanes(
    List<DrawPilot> group,
    LaneMode laneMode,
    SeededRandom random,
  ) {
    random.shuffle(group);
    return [
      for (var i = 0; i < group.length; i++)
        DrawSlot(group[i], laneMode == LaneMode.random ? i + 1 : null),
    ];
  }
}
