import 'package:soar_score_core/soar_score_core.dart';

/// Why a group is a poor place to move a pilot to. The move is still allowed.
enum NotIdealReason { hasScores, roundCompleted, teammate }

/// Why a group cannot be chosen at all.
enum MoveBlockKind {
  /// The pilot flies in this group of this round now.
  currentGroup,

  /// The pilot already flies in this group of another round.
  alreadyInGroup,
  groupLocked,
  roundLocked,

  /// Team protection is on and a teammate flies in the group.
  teamProtection,
}

/// A group of a round as a place to move the pilot to.
class MoveTarget {
  const MoveTarget({
    required this.round,
    required this.group,
    this.block,
    this.notIdeal = const [],
  });

  final Round round;

  /// The group number, from 1.
  final int group;

  /// Why the group cannot be chosen, or `null`.
  final MoveBlockKind? block;
  final List<NotIdealReason> notIdeal;

  bool get allowed => block == null;
  bool get recommended => allowed && notIdeal.isEmpty;
}

/// Why a pilot cannot be moved out of where they are.
enum SourceBlockKind { groupLocked, scoreLocked }

/// A lane of a group: free, or taken by [takenBy].
class LaneOption {
  const LaneOption(this.lane, {this.takenBy});

  final int lane;
  final Id? takenBy;
}

/// Where a pilot can be moved from one assignment: every group of every
/// current round, marked recommended, not ideal or blocked
/// (`plan/ui/contest-administration/matrix.md`). The server enforces the same
/// rules; the plan only shows them before the director asks.
class MovePlan {
  MovePlan._({
    required this.source,
    required this.sourceRound,
    required this.scored,
    required this.sourceBlock,
    required this.targets,
    required this.laneCount,
    required this._lanesTaken,
  });

  /// Builds the plan for moving the pilot of [assignmentId], or `null` when
  /// the matrix has no such live assignment.
  ///
  /// [scores] says which assignments have a score and which scores are
  /// locked. [teamOf] gives each participation its team; [teamsEnabled] and
  /// [teamProtection] come from the contest options.
  static MovePlan? of({
    required CurrentMatrix matrix,
    required ContestScores scores,
    required Id assignmentId,
    required Map<Id, Id> teamOf,
    required bool teamsEnabled,
    required bool teamProtection,
  }) {
    final live = [
      for (final assignment in matrix.assignments)
        if (!assignment.isSuperseded) assignment,
    ];
    final source = live.where((a) => a.id == assignmentId).firstOrNull;
    if (source == null) {
      return null;
    }
    final placeholders = {
      for (final slot in scores.slots)
        slot.placeholder.assignmentId: slot.placeholder,
    };
    bool scoredOf(MatrixAssignment a) =>
        (placeholders[a.id]?.state ?? ScorePlaceholderState.notEntered) !=
        ScorePlaceholderState.notEntered;

    final rounds = [
      for (final round in matrix.rounds)
        if (round.isCurrent) round,
    ]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final roundById = {for (final round in rounds) round.id: round};
    final lockedGroups = {
      for (final group in matrix.groups)
        if (group.isLocked) (group.roundId, group.groupNumber),
    };
    final progress = {
      for (final item
          in scores.rounds.isEmpty ? matrix.progress : scores.rounds)
        item.roundId: item,
    };
    final pilot = source.contestParticipationId;
    final team = teamOf[pilot];
    final pilotAt = {
      for (final a in live)
        if (a.contestParticipationId == pilot) (a.scheduledRoundId, a.group),
    };

    final targets = <MoveTarget>[];
    final lanesTaken = <(Id, int), Map<int, Id>>{};
    var laneCount = 1;
    for (final round in rounds) {
      final inRound = [
        for (final a in live)
          if (a.scheduledRoundId == round.id) a,
      ];
      final originals = <int, int>{};
      for (final a in matrix.assignments) {
        if (a.scheduledRoundId == round.id &&
            a.assignmentType == AssignmentType.original) {
          originals[a.group] = (originals[a.group] ?? 0) + 1;
        }
      }
      final sizes = originals.isEmpty
          ? {
              for (final a in inRound)
                a.group: inRound.where((b) => b.group == a.group).length,
            }
          : originals;
      final capacity = sizes.values.fold<int>(1, (a, b) => a > b ? a : b);
      if (capacity > laneCount) {
        laneCount = capacity;
      }
      for (var group = 1; group <= round.groupCount; group++) {
        final inGroup = [
          for (final a in inRound)
            if (a.group == group) a,
        ];
        lanesTaken[(round.id, group)] = {
          for (final a in inGroup)
            if (a.lane != null && a.id != source.id)
              a.lane!: a.contestParticipationId,
        };
        final teammates =
            teamsEnabled &&
            team != null &&
            inGroup.any(
              (a) =>
                  a.contestParticipationId != pilot &&
                  teamOf[a.contestParticipationId] == team,
            );
        final MoveBlockKind? block;
        if (source.scheduledRoundId == round.id && source.group == group) {
          block = MoveBlockKind.currentGroup;
        } else if (pilotAt.contains((round.id, group))) {
          block = MoveBlockKind.alreadyInGroup;
        } else if (round.status == RoundStatus.locked) {
          block = MoveBlockKind.roundLocked;
        } else if (lockedGroups.contains((round.id, group))) {
          block = MoveBlockKind.groupLocked;
        } else if (teammates && teamProtection) {
          block = MoveBlockKind.teamProtection;
        } else {
          block = null;
        }
        targets.add(
          MoveTarget(
            round: round,
            group: group,
            block: block,
            notIdeal: [
              if (inGroup.any(scoredOf)) NotIdealReason.hasScores,
              if (progress[round.id]?.isComplete ?? false)
                NotIdealReason.roundCompleted,
              if (teammates && !teamProtection) NotIdealReason.teammate,
            ],
          ),
        );
      }
    }

    final sourceRound = roundById[source.scheduledRoundId];
    final sourcePlaceholder = placeholders[source.id];
    final SourceBlockKind? sourceBlock;
    if (lockedGroups.contains((source.scheduledRoundId, source.group))) {
      sourceBlock = SourceBlockKind.groupLocked;
    } else if (sourcePlaceholder?.isLocked ?? false) {
      sourceBlock = SourceBlockKind.scoreLocked;
    } else {
      sourceBlock = null;
    }
    return MovePlan._(
      source: source,
      sourceRound: sourceRound ?? rounds.first,
      scored: scoredOf(source),
      sourceBlock: sourceBlock,
      targets: targets,
      laneCount: laneCount,
      lanesTaken: lanesTaken,
    );
  }

  final MatrixAssignment source;
  final Round sourceRound;

  /// Whether the pilot's flight has a score, which the move discards.
  final bool scored;

  /// Why the pilot cannot be moved out of their group, or `null`.
  final SourceBlockKind? sourceBlock;
  final List<MoveTarget> targets;

  /// The lanes of the largest group the draw made, which bounds the lane
  /// picker. Only used when the contest has lanes.
  final int laneCount;
  final Map<(Id, int), Map<int, Id>> _lanesTaken;

  /// The groups of [round], in group order.
  List<MoveTarget> groupsOf(Round round) => [
    for (final target in targets)
      if (target.round.id == round.id) target,
  ];

  List<Round> get rounds => [
    for (final target in targets)
      if (target.group == 1) target.round,
  ];

  /// The lanes of [target], with the pilot who holds each taken one.
  List<LaneOption> lanesOf(MoveTarget target) {
    final taken = _lanesTaken[(target.round.id, target.group)] ?? const {};
    return [
      for (var lane = 1; lane <= laneCount; lane++)
        LaneOption(lane, takenBy: taken[lane]),
    ];
  }
}
