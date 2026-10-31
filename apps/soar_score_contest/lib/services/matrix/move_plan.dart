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
enum SourceBlockKind { groupLocked, scoreLocked, pilotRetired }

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
    required this.rounds,
    required this.scored,
    required this.sourceBlock,
    required this.targets,
    required this.laneCount,
    required this._lanesTaken,
  });

  /// Builds the plan for moving the pilot of [assignmentId], or `null` when
  /// the matrix has no such live assignment in a current round (the page is
  /// out of date).
  ///
  /// [scores] says which assignments have a score and which scores are
  /// locked. [teamOf] gives each participation its team; [teamsEnabled] and
  /// [teamProtection] come from the contest options. [pilotRetired] is
  /// whether the pilot has retired.
  static MovePlan? of({
    required CurrentMatrix matrix,
    required ContestScores scores,
    required Id assignmentId,
    required Map<Id, Id> teamOf,
    required bool teamsEnabled,
    required bool teamProtection,
    bool pilotRetired = false,
  }) {
    final live = [
      for (final assignment in matrix.assignments)
        if (!assignment.isSuperseded) assignment,
    ];
    final source = live.where((a) => a.id == assignmentId).firstOrNull;
    final rounds = [
      for (final round in matrix.rounds)
        if (round.isCurrent) round,
    ]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final sourceRound = source == null
        ? null
        : rounds.where((r) => r.id == source.scheduledRoundId).firstOrNull;
    if (source == null || sourceRound == null) {
      return null;
    }
    final context = _Context(
      live: live,
      source: source,
      placeholders: {
        for (final slot in scores.slots)
          slot.placeholder.assignmentId: slot.placeholder,
      },
      lockedGroups: {
        for (final group in matrix.groups)
          if (group.isLocked) (group.roundId, group.groupNumber),
      },
      progress: {
        for (final item
            in scores.rounds.isEmpty ? matrix.progress : scores.rounds)
          item.roundId: item,
      },
      teamOf: teamOf,
      teamsEnabled: teamsEnabled,
      teamProtection: teamProtection,
    );

    final targets = <MoveTarget>[];
    final lanesTaken = <(Id, int), Map<int, Id>>{};
    var laneCount = 1;
    for (final round in rounds) {
      final capacity = _laneCapacity(round, matrix.assignments, live);
      if (capacity > laneCount) {
        laneCount = capacity;
      }
      for (var group = 1; group <= round.groupCount; group++) {
        final inGroup = [
          for (final a in live)
            if (a.scheduledRoundId == round.id && a.group == group) a,
        ];
        lanesTaken[(round.id, group)] = {
          for (final a in inGroup)
            if (a.lane != null && a.id != source.id)
              a.lane!: a.contestParticipationId,
        };
        final teammate = context.teammateIn(inGroup);
        targets.add(
          MoveTarget(
            round: round,
            group: group,
            block: context.blockFor(round, group, teammate),
            notIdeal: context.notIdealFor(round, inGroup, teammate),
          ),
        );
      }
    }
    return MovePlan._(
      source: source,
      sourceRound: sourceRound,
      rounds: rounds,
      scored: context.isScored(source),
      sourceBlock: pilotRetired
          ? SourceBlockKind.pilotRetired
          : context.sourceBlock(),
      targets: targets,
      laneCount: laneCount,
      lanesTaken: lanesTaken,
    );
  }

  /// The size of the largest group the draw made in [round], which bounds
  /// its lanes. Falls back to the live groups when the originals are gone.
  static int _laneCapacity(
    Round round,
    List<MatrixAssignment> all,
    List<MatrixAssignment> live,
  ) {
    Map<int, int> sizes(Iterable<MatrixAssignment> rows) {
      final result = <int, int>{};
      for (final a in rows) {
        if (a.scheduledRoundId == round.id) {
          result[a.group] = (result[a.group] ?? 0) + 1;
        }
      }
      return result;
    }

    final originals = sizes(
      all.where((a) => a.assignmentType == AssignmentType.original),
    );
    final counts = (originals.isEmpty ? sizes(live) : originals).values;
    return counts.fold<int>(1, (a, b) => a > b ? a : b);
  }

  final MatrixAssignment source;
  final Round sourceRound;

  /// The current rounds, in order.
  final List<Round> rounds;

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

  /// The lanes of [target], with the pilot who holds each taken one.
  List<LaneOption> lanesOf(MoveTarget target) {
    final taken = _lanesTaken[(target.round.id, target.group)] ?? const {};
    return [
      for (var lane = 1; lane <= laneCount; lane++)
        LaneOption(lane, takenBy: taken[lane]),
    ];
  }
}

/// What the rules of one plan look at.
class _Context {
  _Context({
    required this.live,
    required this.source,
    required this.placeholders,
    required this.lockedGroups,
    required this.progress,
    required this.teamOf,
    required this.teamsEnabled,
    required this.teamProtection,
  }) : pilotAt = {
         for (final a in live)
           if (a.contestParticipationId == source.contestParticipationId)
             (a.scheduledRoundId, a.group),
       };

  final List<MatrixAssignment> live;
  final MatrixAssignment source;
  final Map<Id, ScorePlaceholder> placeholders;
  final Set<(Id, int)> lockedGroups;
  final Map<Id, RoundProgress> progress;
  final Map<Id, Id> teamOf;
  final bool teamsEnabled;
  final bool teamProtection;

  /// The groups the pilot flies in, as (round id, group).
  final Set<(Id, int)> pilotAt;

  bool isScored(MatrixAssignment a) =>
      (placeholders[a.id]?.state ?? ScorePlaceholderState.notEntered) !=
      ScorePlaceholderState.notEntered;

  /// Whether a teammate of the pilot flies in [inGroup].
  bool teammateIn(List<MatrixAssignment> inGroup) {
    final team = teamOf[source.contestParticipationId];
    return teamsEnabled &&
        team != null &&
        inGroup.any(
          (a) =>
              a.contestParticipationId != source.contestParticipationId &&
              teamOf[a.contestParticipationId] == team,
        );
  }

  MoveBlockKind? blockFor(Round round, int group, bool teammate) {
    if (source.scheduledRoundId == round.id && source.group == group) {
      return MoveBlockKind.currentGroup;
    }
    if (pilotAt.contains((round.id, group))) {
      return MoveBlockKind.alreadyInGroup;
    }
    if (round.status == RoundStatus.locked) {
      return MoveBlockKind.roundLocked;
    }
    if (lockedGroups.contains((round.id, group))) {
      return MoveBlockKind.groupLocked;
    }
    if (teammate && teamProtection) {
      return MoveBlockKind.teamProtection;
    }
    return null;
  }

  List<NotIdealReason> notIdealFor(
    Round round,
    List<MatrixAssignment> inGroup,
    bool teammate,
  ) => [
    if (inGroup.any(isScored)) NotIdealReason.hasScores,
    if (progress[round.id]?.isComplete ?? false) NotIdealReason.roundCompleted,
    if (teammate && !teamProtection) NotIdealReason.teammate,
  ];

  SourceBlockKind? sourceBlock() {
    if (lockedGroups.contains((source.scheduledRoundId, source.group))) {
      return SourceBlockKind.groupLocked;
    }
    if (placeholders[source.id]?.isLocked ?? false) {
      return SourceBlockKind.scoreLocked;
    }
    return null;
  }
}
