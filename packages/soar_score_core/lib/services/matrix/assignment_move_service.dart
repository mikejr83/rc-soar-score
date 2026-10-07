import 'dart:math';

import '../../enums/admin_lock.dart';
import '../../enums/assignment_type.dart';
import '../../enums/existing_score_handling.dart';
import '../../enums/lane_mode.dart';
import '../../enums/lifecycle_state.dart';
import '../../enums/score_placeholder_state.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/matrix/current_matrix.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/round.dart';
import '../../models/scores/score_placeholder.dart';
import '../../repositories/already_stored_error.dart';
import '../../repositories/mutation_metadata.dart';
import '../../repositories/repository.dart';
import 'matrix_service.dart';

/// Moves a pilot to another group, lane or round of the current matrix.
///
/// A move never changes a stored assignment. It adds a `Moved` row that
/// replaces the old one and an empty score placeholder for it. When the old
/// assignment already had a score, the move is a reset: the old score stays
/// in the history and stops counting, and the pilot flies the new slot with an
/// empty score. See `plan/data-model/entities/matrix_assignment.md`.
class AssignmentMoveService {
  AssignmentMoveService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Moves the pilot of assignment [sourceId] in contest [contestId] to
  /// [group] and [lane] of round [scheduledRoundId] (the source's own round
  /// when null), as new assignment [id], and returns the current matrix.
  ///
  /// Idempotent on [id]: repeating a move returns the matrix as it is.
  /// [reason] is required. [overrideLocks] lets the director move across a
  /// locked group or a locked score; the reason then records why.
  ///
  /// Throws:
  /// - `EntityNotFoundError` for an unknown contest, assignment or round;
  /// - `AlreadyStoredError` when [id] belongs to another contest;
  /// - `ContestStateError` when the contest has no matrix to edit, is locked
  ///   or completed, the assignment or round is no longer current, the pilot
  ///   retired, the lane is taken, the pilot is already in the group, a
  ///   teammate is in the group, a group or score is locked, or the move
  ///   changes nothing;
  /// - `ArgumentError` for a blank [reason], a [group] outside the round, or
  ///   a [lane] that does not fit the contest's lane mode.
  Future<CurrentMatrix> move(
    Id contestId,
    Id sourceId, {
    required Id id,
    Id? scheduledRoundId,
    required int group,
    int? lane,
    required String reason,
    bool overrideLocks = false,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final stored = await repository.matrixAssignmentRepository.findById(id);
    if (stored != null) {
      if (stored.contestId != contestId) {
        throw AlreadyStoredError(entityType: 'MatrixAssignment', entityId: id);
      }
      return MatrixService(repository).current(contestId);
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('a reason is required to move a pilot');
    }
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'contest_locked',
        'the contest is locked; unlock it to move a pilot',
      );
    }
    if (contest.lifecycleState != LifecycleState.ready &&
        contest.lifecycleState != LifecycleState.running) {
      throw ContestStateError(
        'matrix_not_editable',
        'pilots can be moved once the matrix is drawn and until the contest '
            'is completed',
      );
    }

    final source = await repository.matrixAssignmentRepository.findById(
      sourceId,
    );
    if (source == null || source.contestId != contestId) {
      throw EntityNotFoundError(
        entityType: 'MatrixAssignment',
        entityId: sourceId,
      );
    }
    if (source.isSuperseded) {
      throw ContestStateError(
        'assignment_superseded',
        'this assignment was already moved; move the pilot from the current '
            'assignment',
      );
    }
    final rounds = {
      for (final round in await repository.roundRepository.listForContest(
        contestId,
      ))
        round.id: round,
    };
    final sourceRound = rounds[source.scheduledRoundId]!;
    if (!sourceRound.isCurrent) {
      throw ContestStateError(
        'round_not_current',
        'the assignment belongs to a round that is no longer current',
      );
    }
    final targetRound = scheduledRoundId == null
        ? sourceRound
        : rounds[scheduledRoundId] ??
              (throw EntityNotFoundError(
                entityType: 'Round',
                entityId: scheduledRoundId,
              ));
    if (!targetRound.isCurrent) {
      throw ContestStateError(
        'round_not_current',
        'the target round is no longer current',
      );
    }

    final participation = await repository.contestParticipationRepository
        .findById(source.contestParticipationId);
    if (participation == null || participation.isRetired) {
      throw ContestStateError(
        'pilot_retired',
        'a retired pilot cannot be moved',
      );
    }

    final live = await repository.matrixAssignmentRepository.listLiveForRound(
      targetRound.id,
    );
    await _checkSlot(
      contestId: contestId,
      round: targetRound,
      group: group,
      lane: lane,
      live: live,
    );
    _checkTargetFree(source: source, live: live, group: group, lane: lane);
    await _checkTeams(
      contestId: contestId,
      participationId: source.contestParticipationId,
      live: live,
      group: group,
    );

    final sourcePlaceholder = await repository.scorePlaceholderRepository
        .findForAssignment(sourceId);
    final scored =
        sourcePlaceholder != null &&
        sourcePlaceholder.state != ScorePlaceholderState.notEntered;
    final sameSlot =
        source.scheduledRoundId == targetRound.id &&
        source.group == group &&
        source.lane == lane;
    if (sameSlot && !scored) {
      throw ContestStateError(
        'no_change',
        'the pilot is already in this slot; a move to the same slot only '
            'resets a score entered in the wrong place',
      );
    }
    await _checkLocks(
      source: source,
      sourcePlaceholder: sourcePlaceholder,
      targetRound: targetRound,
      group: group,
      overrideLocks: overrideLocks,
    );

    final moved = MatrixAssignment(
      id: id,
      contestId: contestId,
      matrixRevisionId: targetRound.matrixRevisionId,
      contestParticipationId: source.contestParticipationId,
      scheduledRoundId: targetRound.id,
      creditedRoundId: source.creditedRoundId,
      group: group,
      lane: lane,
      flightSequence: source.flightSequence,
      assignmentType: AssignmentType.moved,
      sourceAssignmentId: source.id,
      actorId: actorId,
      reason: reason.trim(),
      existingScoreHandling: scored
          ? ExistingScoreHandling.reset
          : ExistingScoreHandling.none,
      resetScoreRevision: scored ? sourcePlaceholder.scoreRevision : null,
      createdAt: _clock(),
    );
    await repository.matrixAssignmentRepository.move(
      moved,
      placeholder: ScorePlaceholder(
        id: _newId(),
        contestId: contestId,
        contestParticipationId: source.contestParticipationId,
        assignmentId: id,
      ),
      metadata: metadata,
    );
    return MatrixService(repository).current(contestId);
  }

  /// Checks that [group] and [lane] exist in [round] and fit the contest's
  /// lane mode.
  Future<void> _checkSlot({
    required Id contestId,
    required Round round,
    required int group,
    required int? lane,
    required List<MatrixAssignment> live,
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
    // The lanes of a round are as many as its largest group of the draw.
    final sizes = <int, int>{};
    for (final assignment in live) {
      if (assignment.assignmentType == AssignmentType.original) {
        sizes.update(assignment.group, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final laneCount = sizes.values.fold<int>(1, max);
    if (lane == null || lane < 1 || lane > laneCount) {
      throw ArgumentError('lane must be between 1 and $laneCount');
    }
  }

  void _checkTargetFree({
    required MatrixAssignment source,
    required List<MatrixAssignment> live,
    required int group,
    required int? lane,
  }) {
    for (final other in live) {
      if (other.id == source.id) continue;
      if (other.group != group) continue;
      if (other.contestParticipationId == source.contestParticipationId) {
        throw ContestStateError(
          'already_in_group',
          'the pilot already flies in this group',
        );
      }
      if (lane != null && other.lane == lane) {
        throw ContestStateError(
          'lane_taken',
          'lane $lane of group $group is taken by another pilot',
        );
      }
    }
  }

  Future<void> _checkTeams({
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

  Future<void> _checkLocks({
    required MatrixAssignment source,
    required ScorePlaceholder? sourcePlaceholder,
    required Round targetRound,
    required int group,
    required bool overrideLocks,
  }) async {
    if (overrideLocks) return;
    final groups = repository.roundGroupRepository;
    for (final (roundId, number) in [
      (source.scheduledRoundId, source.group),
      (targetRound.id, group),
    ]) {
      final locked = (await groups.listForRound(roundId))
          .any((g) => g.groupNumber == number && g.isLocked);
      if (locked) {
        throw ContestStateError(
          'group_locked',
          'group $number is locked; unlock it or override the lock',
        );
      }
    }
    if (sourcePlaceholder != null && sourcePlaceholder.isLocked) {
      throw ContestStateError(
        'score_locked',
        'the pilot\'s score is locked; unlock it or override the lock',
      );
    }
  }

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }
}
