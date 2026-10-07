import 'dart:math';

import '../../enums/assignment_type.dart';
import '../../enums/lane_mode.dart';
import '../../errors/contest_state_error.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/round.dart';
import '../../repositories/repository.dart';

/// The rules about where a pilot may sit in a round, shared by the edits that
/// place a pilot after the draw (moves and late adds).
class MatrixSlotRules {
  MatrixSlotRules(this.repository);

  final Repository repository;

  /// Every assignment ever scheduled in [round], replaced ones included.
  Future<List<MatrixAssignment>> assignmentsOfRound(Round round) async => [
    for (final assignment
        in await repository.matrixAssignmentRepository.listForRevision(
          round.matrixRevisionId,
        ))
      if (assignment.scheduledRoundId == round.id) assignment,
  ];

  /// The assignments of [rows] that no move has replaced.
  List<MatrixAssignment> live(List<MatrixAssignment> rows) => [
    for (final row in rows)
      if (!row.isSuperseded) row,
  ];

  /// The size of the largest group the draw made in [round]: the lanes of the
  /// round, and the room of every group.
  int capacity(List<MatrixAssignment> rows) {
    final sizes = <int, int>{};
    for (final row in rows) {
      if (row.assignmentType == AssignmentType.original) {
        sizes.update(row.group, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return sizes.values.fold<int>(1, max);
  }

  /// How many pilots a regular group of the round can hold: the draw's
  /// `ceil(N / G)` for N original assignments in G groups. Late adds never
  /// grow a group beyond it.
  int groupCapacity(Round round, List<MatrixAssignment> rows) {
    final originals = rows
        .where((row) => row.assignmentType == AssignmentType.original)
        .length;
    return (originals + round.groupCount - 1) ~/ round.groupCount;
  }

  /// Checks that [group] and [lane] exist in [round] (whose assignments are
  /// [rows]) and fit the contest's lane mode.
  Future<void> checkSlot({
    required Id contestId,
    required Round round,
    required List<MatrixAssignment> rows,
    required int group,
    required int? lane,
  }) async {
    if (group < 1 || group > round.groupCount) {
      throw ArgumentError(
        'group must be between 1 and ${round.groupCount} for this round',
      );
    }
    final configuration = await repository
        .contestConfigurationRevisionRepository
        .latestForContest(contestId);
    final laneMode =
        configuration?.config.coreOptions.laneMode ?? LaneMode.none;
    if (laneMode == LaneMode.none) {
      if (lane != null) {
        throw ArgumentError('the contest has no lanes; leave lane empty');
      }
      return;
    }
    final laneCount = capacity(rows);
    if (lane == null || lane < 1 || lane > laneCount) {
      throw ArgumentError('lane must be between 1 and $laneCount');
    }
  }

  /// Throws when team protection is on and a teammate of
  /// [participationId] already flies in [group] among [live].
  Future<void> checkTeams({
    required Id contestId,
    required Id participationId,
    required List<MatrixAssignment> live,
    required int group,
  }) async {
    final configuration = await repository
        .contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (configuration?.config.coreOptions.teamProtection != true) return;
    final teamOf = {
      for (final membership
          in await repository.teamMembershipRepository.listForContest(
            contestId,
          ))
        membership.contestParticipationId: membership.teamId,
    };
    final team = teamOf[participationId];
    if (team == null) return;
    for (final other in live) {
      if (other.group == group &&
          other.contestParticipationId != participationId &&
          teamOf[other.contestParticipationId] == team) {
        throw ContestStateError(
          'team_conflict',
          'a teammate already flies in this group',
        );
      }
    }
  }
}
