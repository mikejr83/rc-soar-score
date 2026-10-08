import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_pilot.dart';
import 'round_progress_view.dart';

/// One pilot's place in a group of a round.
class GridSlot {
  const GridSlot({required this.pilot, required this.lane});

  final MatrixPilot pilot;
  final int? lane;
}

/// A round of the drawn matrix with its groups, in group order.
class GridRound {
  const GridRound({
    required this.ordinal,
    required this.status,
    required this.groups,
    this.scored = 0,
    int? total,
  }) : total = total ?? -1;

  final int ordinal;
  final RoundStatus status;

  /// Flights of the round with an official score.
  final int scored;

  /// Live flights of the round; the pilot slots when the server sent no
  /// count.
  final int total;

  /// Slots per group, group A first.
  final List<List<GridSlot>> groups;

  /// The state shown in the round header.
  RoundProgressView get progress => RoundProgressView.of(
    status,
    scored: scored,
    total: total < 0 ? pilotCount : total,
  );

  bool get isLocked => status == RoundStatus.locked;

  int get pilotCount => groups.fold(0, (total, group) => total + group.length);

  /// How many different pilots the round holds; equals [pilotCount] when
  /// every pilot appears exactly once.
  int get distinctPilots => {
    for (final group in groups)
      for (final slot in group) slot.pilot.participationId,
  }.length;
}

/// The drawn matrix arranged for the grid: rounds by groups by slots, plus
/// how often pilots meet.
class MatrixGridModel {
  MatrixGridModel._({
    required this.rounds,
    required this.pilots,
    required this.hasLanes,
    required this._meetings,
  });

  /// Arranges [matrix]; [pilots] gives each participation its display
  /// data. Superseded rounds and assignments are left out.
  factory MatrixGridModel.of(
    CurrentMatrix matrix,
    Map<Id, MatrixPilot> pilots,
  ) {
    final groupsByRound = <Id, List<RoundGroup>>{};
    for (final group in matrix.groups) {
      groupsByRound.putIfAbsent(group.roundId, () => []).add(group);
    }
    final assignmentsByCell = <(Id, int), List<MatrixAssignment>>{};
    for (final assignment in matrix.assignments) {
      if (assignment.isSuperseded) {
        continue;
      }
      assignmentsByCell
          .putIfAbsent((
            assignment.scheduledRoundId,
            assignment.group,
          ), () => [])
          .add(assignment);
    }
    final progressByRound = {
      for (final progress in matrix.progress) progress.roundId: progress,
    };
    final current = matrix.rounds.where((round) => round.isCurrent).toList()
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    var lanes = false;
    final rounds = <GridRound>[];
    for (final round in current) {
      final numbers = {
        for (final group in groupsByRound[round.id] ?? const <RoundGroup>[])
          group.groupNumber,
        for (var n = 1; n <= round.groupCount; n++) n,
      }.toList()..sort();
      final groups = <List<GridSlot>>[];
      for (final number in numbers) {
        final slots = <GridSlot>[
          for (final assignment
              in assignmentsByCell[(round.id, number)] ??
                  const <MatrixAssignment>[])
            GridSlot(
              pilot:
                  pilots[assignment.contestParticipationId] ??
                  _unknown(assignment),
              lane: assignment.lane,
            ),
        ];
        lanes = lanes || slots.any((slot) => slot.lane != null);
        slots.sort(_bySlot);
        groups.add(slots);
      }
      final progress = progressByRound[round.id];
      rounds.add(
        GridRound(
          ordinal: round.ordinal,
          status: round.status,
          groups: groups,
          scored: progress?.scored ?? 0,
          total: progress?.total,
        ),
      );
    }

    final seen = <Id, MatrixPilot>{};
    final meetings = <Id, Map<Id, int>>{};
    for (final round in rounds) {
      for (final group in round.groups) {
        for (final a in group) {
          seen[a.pilot.participationId] = a.pilot;
          for (final b in group) {
            if (a.pilot.participationId != b.pilot.participationId) {
              final row = meetings.putIfAbsent(
                a.pilot.participationId,
                () => {},
              );
              row[b.pilot.participationId] =
                  (row[b.pilot.participationId] ?? 0) + 1;
            }
          }
        }
      }
    }
    final ordered = seen.values.toList()..sort(_byPilot);
    return MatrixGridModel._(
      rounds: rounds,
      pilots: ordered,
      hasLanes: lanes,
      meetings: meetings,
    );
  }

  static MatrixPilot _unknown(MatrixAssignment assignment) => MatrixPilot(
    participationId: assignment.contestParticipationId,
    number: null,
    name: 'Unknown pilot',
    role: 'Pilot',
    teamId: null,
  );

  static int _byPilot(MatrixPilot a, MatrixPilot b) {
    final byNumber = (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30);
    return byNumber != 0 ? byNumber : a.name.compareTo(b.name);
  }

  static int _bySlot(GridSlot a, GridSlot b) {
    if (a.lane != null && b.lane != null) {
      return a.lane!.compareTo(b.lane!);
    }
    return _byPilot(a.pilot, b.pilot);
  }

  final List<GridRound> rounds;

  /// Every pilot in the matrix, in number order.
  final List<MatrixPilot> pilots;

  /// Whether the draw gave lanes.
  final bool hasLanes;

  final Map<Id, Map<Id, int>> _meetings;

  int get groupCount => rounds.isEmpty ? 0 : rounds.first.groups.length;

  /// How often [pilot] shares a group with [other].
  int meetingsBetween(Id pilot, Id other) => _meetings[pilot]?[other] ?? 0;

  /// The other pilots with the number of times each meets [pilot], most
  /// meetings first, then by pilot number.
  List<(MatrixPilot, int)> opponentsOf(Id pilot) => [
    for (final other in pilots)
      if (other.participationId != pilot)
        (other, meetingsBetween(pilot, other.participationId)),
  ]..sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : _byPilot(a.$1, b.$1));

  /// The round, group letter index and lane where [pilot] flies in [round].
  (int group, int? lane)? placeOf(Id pilot, GridRound round) {
    for (var g = 0; g < round.groups.length; g++) {
      for (final slot in round.groups[g]) {
        if (slot.pilot.participationId == pilot) {
          return (g, slot.lane);
        }
      }
    }
    return null;
  }
}
