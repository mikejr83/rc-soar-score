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

/// The draw behind the first matrix API: balanced groups, teammates kept
/// apart, and pilots spread so that as few pairs as possible meet again.
///
/// Rounds are built one after another. Each round is built [attemptsPerRound]
/// times, every pilot going to the open group where they meet the opponents
/// they have met least in the earlier rounds, and the build that keeps the
/// meeting counts most even (the lowest sum of squared counts) is kept. The
/// optimizer (`matrix-draw.md`) improves a draw like this one across all
/// rounds later; the inputs, the seed and the output shape stay the same.
///
/// A draw can continue earlier rounds: the meetings of those rounds count as
/// if they were the first rounds of this draw.
class BasicDraw {
  const BasicDraw();

  /// How many times a round is built by default.
  static const int defaultAttemptsPerRound = 50;

  /// The most attempts a round may ask for.
  static const int maxAttemptsPerRound = 200;

  /// The groups of each of [rounds] rounds: `result[round][group]` lists the
  /// slots of that group, with lanes when [laneMode] is `random`.
  ///
  /// With [teamProtection], no two pilots of a team share a group; that needs
  /// at least as many groups as the largest team ([ArgumentError] otherwise).
  /// With [spreadMeetings] off, pilots are dealt without looking at who they
  /// have met and [attemptsPerRound] is ignored (a random valid draw, the
  /// baseline of the fairness score).
  /// With [allowBackToBack] off, no pilot flies in the last group of one
  /// round and the first group of the next, including the first new round
  /// against the last round of [history]; an [ArgumentError] naming the
  /// back-to-back constraint is thrown when no draw can satisfy it.
  /// [history] holds the rounds flown or kept before these ones. Pilots who
  /// are not in [pilots] (they retired) are ignored.
  /// Throws an [ArgumentError] when the settings cannot be met.
  List<List<List<DrawSlot>>> generate({
    required List<DrawPilot> pilots,
    required int rounds,
    required int groupsPerRound,
    required bool teamProtection,
    required LaneMode laneMode,
    required SeededRandom random,
    int attemptsPerRound = defaultAttemptsPerRound,
    bool spreadMeetings = true,
    bool allowBackToBack = true,
    List<List<List<DrawSlot>>> history = const [],
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
    if (attemptsPerRound < 1 || attemptsPerRound > maxAttemptsPerRound) {
      throw ArgumentError.value(
        attemptsPerRound,
        'attemptsPerRound',
        'must be between 1 and $maxAttemptsPerRound',
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
    // How often each pair of pilots (by position) has met so far.
    final meetings = [
      for (final _ in pilots) List<int>.filled(pilots.length, 0),
    ];
    final position = {
      for (var i = 0; i < pilots.length; i++) pilots[i].participationId: i,
    };
    for (final round in history) {
      for (final group in round) {
        final present = [
          for (final slot in group)
            if (position[slot.pilot.participationId] != null)
              position[slot.pilot.participationId]!,
        ];
        for (var i = 0; i < present.length; i++) {
          for (var j = i + 1; j < present.length; j++) {
            meetings[present[i]][present[j]]++;
            meetings[present[j]][present[i]]++;
          }
        }
      }
    }
    // The pilots of the last group of the round before, who may not open
    // the next round when back-to-back flights are off.
    var blocked = <int>{};
    if (!allowBackToBack && history.isNotEmpty && history.last.isNotEmpty) {
      blocked = {
        for (final slot in history.last.last)
          if (position[slot.pilot.participationId] != null)
            position[slot.pilot.participationId]!,
      };
    }
    final result = <List<List<DrawSlot>>>[];
    for (var round = 0; round < rounds; round++) {
      final groups = _round(
        pilots,
        groupsPerRound,
        teamProtection,
        spreadMeetings ? attemptsPerRound : 1,
        meetings,
        random,
        spreadMeetings,
        blocked,
      );
      if (!allowBackToBack) blocked = groups.last.toSet();
      for (final group in groups) {
        for (var i = 0; i < group.length; i++) {
          for (var j = i + 1; j < group.length; j++) {
            meetings[group[i]][group[j]]++;
            meetings[group[j]][group[i]]++;
          }
        }
      }
      result.add([
        for (final group in groups)
          _withLanes([for (final i in group) pilots[i]], laneMode, random),
      ]);
    }
    return result;
  }

  /// The message of the error thrown when back-to-back flights are off and
  /// no draw can avoid them.
  static const String backToBackMessage =
      'no draw can avoid back-to-back flights (a pilot in the last group of '
      'one round and the first group of the next) with these groups; use '
      'more groups or allow back-to-back flights';

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

  /// The best of [attempts] builds of one round, as groups of pilot positions.
  List<List<int>> _round(
    List<DrawPilot> pilots,
    int groupCount,
    bool teamProtection,
    int attempts,
    List<List<int>> meetings,
    SeededRandom random,
    bool spreadMeetings,
    Set<int> blocked,
  ) {
    List<List<int>>? best;
    var bestCost = 0;
    var built = 0;
    // A build can dead-end (no group left free of teammates); those are
    // tried again without counting as an attempt, up to a limit.
    for (var tries = 0; built < attempts && tries < attempts + 200; tries++) {
      final groups = _build(
        pilots,
        groupCount,
        teamProtection,
        meetings,
        random,
        spreadMeetings,
        blocked,
      );
      if (groups == null) {
        continue;
      }
      built++;
      final cost = _cost(groups, meetings);
      if (best == null || cost < bestCost) {
        best = groups;
        bestCost = cost;
      }
    }
    if (best == null && blocked.isNotEmpty) {
      // Name back-to-back only when the round can be built without it.
      final withoutIt = _tryRound(
        pilots,
        groupCount,
        teamProtection,
        meetings,
        random,
        spreadMeetings,
      );
      if (withoutIt) {
        throw ArgumentError(backToBackMessage);
      }
    }
    if (best == null) {
      throw ArgumentError(
        'no draw keeps every team apart with $groupCount groups; use more '
        'groups',
      );
    }
    return best;
  }

  /// Whether one round can be built at all, ignoring back-to-back flights.
  bool _tryRound(
    List<DrawPilot> pilots,
    int groupCount,
    bool teamProtection,
    List<List<int>> meetings,
    SeededRandom random,
    bool spreadMeetings,
  ) {
    for (var tries = 0; tries < 50; tries++) {
      if (_build(
            pilots,
            groupCount,
            teamProtection,
            meetings,
            random,
            spreadMeetings,
            const {},
          ) !=
          null) {
        return true;
      }
    }
    return false;
  }

  /// What a build adds to the sum of squared meeting counts: a pair that has
  /// met `c` times costs `2c + 1` to meet once more.
  int _cost(List<List<int>> groups, List<List<int>> meetings) {
    var cost = 0;
    for (final group in groups) {
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          cost += 2 * meetings[group[i]][group[j]] + 1;
        }
      }
    }
    return cost;
  }

  /// One build of a round, or `null` when it left a pilot with no open group
  /// free of teammates.
  List<List<int>>? _build(
    List<DrawPilot> pilots,
    int groupCount,
    bool teamProtection,
    List<List<int>> meetings,
    SeededRandom random,
    bool spreadMeetings,
    Set<int> blocked,
  ) {
    final base = pilots.length ~/ groupCount;
    final extra = pilots.length % groupCount;
    // Which groups take the extra pilot differs from build to build.
    final order = random.shuffle([for (var g = 0; g < groupCount; g++) g]);
    // Group 1 takes no pilot of [blocked], so it must not take the extra
    // pilot when that would leave too few others to fill it.
    if (blocked.isNotEmpty &&
        extra > 0 &&
        pilots.length - blocked.length < base + 1) {
      order.remove(0);
      order.add(0);
    }
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
    final queue = random.shuffle([for (var i = 0; i < pilots.length; i++) i]);
    int size(int p) {
      final team = pilots[p].teamId;
      return team == null ? 0 : teamSizes[team]!;
    }

    // Pilots barred from group 1 are placed first, so they leave room for
    // the others there.
    int barred(int p) => blocked.contains(p) ? 1 : 0;
    final indexed = [for (var i = 0; i < queue.length; i++) (i, queue[i])]
      ..sort((a, b) {
        final byBarred = barred(b.$2).compareTo(barred(a.$2));
        if (byBarred != 0) return byBarred;
        final bySize = size(b.$2).compareTo(size(a.$2));
        return bySize != 0 ? bySize : a.$1.compareTo(b.$1);
      });

    final groups = [for (var g = 0; g < groupCount; g++) <int>[]];
    final teamsIn = [for (var g = 0; g < groupCount; g++) <Id>{}];
    for (final (_, pilot) in indexed) {
      final team = pilots[pilot].teamId;
      var bestAdded = 0;
      final candidates = <int>[];
      for (var g = 0; g < groupCount; g++) {
        if (capacity[g] - groups[g].length <= 0 ||
            (g == 0 && blocked.contains(pilot)) ||
            (teamProtection && team != null && teamsIn[g].contains(team))) {
          continue;
        }
        // What this pilot adds in this group: the opponents met least win.
        var added = 0;
        if (spreadMeetings) {
          for (final other in groups[g]) {
            added += 2 * meetings[pilot][other] + 1;
          }
        }
        if (candidates.isEmpty || added < bestAdded) {
          bestAdded = added;
          candidates
            ..clear()
            ..add(g);
        } else if (added == bestAdded) {
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
