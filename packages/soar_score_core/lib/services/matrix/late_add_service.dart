import 'dart:math';

import '../../enums/admin_lock.dart';
import '../../enums/assignment_type.dart';
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
import 'matrix_slot_rules.dart';

/// Places a pilot who joined after the draw, or who is making up a missed
/// round, in a group of the current matrix.
///
/// A late add never changes a stored assignment: it adds a `LateAdd` row and
/// an empty score placeholder. See
/// `plan/data-model/entities/matrix_assignment.md`.
class LateAddService {
  LateAddService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;
  late final _rules = MatrixSlotRules(repository);

  /// Places participation [participationId] of contest [contestId] in [group]
  /// and [lane] of round [scheduledRoundId], as new assignment [id]. The
  /// flight counts toward [creditedRoundId], the scheduled round when null.
  /// Returns the current matrix.
  ///
  /// Idempotent on [id]: repeating a late add returns the matrix as it is.
  /// A pilot without a participant number receives the next one.
  ///
  /// Throws:
  /// - `EntityNotFoundError` for an unknown contest, participation or round;
  /// - `AlreadyStoredError` when [id] belongs to another contest;
  /// - `ContestStateError` when the contest has no matrix to edit, is locked
  ///   or completed, the participation is not a pilot or has retired, a round
  ///   is no longer current, the pilot already flies the credited round or
  ///   the group, the group is locked, has flown, is full, or the lane is
  ///   taken, or a teammate is in the group;
  /// - `ArgumentError` for a blank [reason], a [group] outside the round, or
  ///   a [lane] that does not fit the contest's lane mode.
  Future<CurrentMatrix> add(
    Id contestId, {
    required Id id,
    required Id participationId,
    required Id scheduledRoundId,
    Id? creditedRoundId,
    required int group,
    int? lane,
    required String reason,
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
      throw ArgumentError('a reason is required to add a pilot late');
    }
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'contest_locked',
        'the contest is locked; unlock it to add a pilot',
      );
    }
    if (contest.lifecycleState != LifecycleState.ready &&
        contest.lifecycleState != LifecycleState.running) {
      throw ContestStateError(
        'matrix_not_editable',
        'pilots can be added late once the matrix is drawn and until the '
            'contest is completed',
      );
    }

    final participations = await repository.contestParticipationRepository
        .listForContest(contestId);
    final participation = participations
        .where((p) => p.id == participationId)
        .firstOrNull;
    if (participation == null) {
      throw EntityNotFoundError(
        entityType: 'ContestParticipation',
        entityId: participationId,
      );
    }
    if (!participation.isPilot) {
      throw ContestStateError(
        'not_a_pilot',
        'only a pilot can be placed in a group',
      );
    }
    if (participation.isRetired) {
      throw ContestStateError(
        'pilot_retired',
        'a retired pilot cannot be added to a group',
      );
    }

    final rounds = {
      for (final round in await repository.roundRepository.listForContest(
        contestId,
      ))
        round.id: round,
    };
    final scheduled = _currentRound(rounds, scheduledRoundId);
    final credited = _currentRound(rounds, creditedRoundId ?? scheduledRoundId);

    final held = await repository.matrixAssignmentRepository
        .listForParticipation(participationId);
    for (final assignment in held) {
      if (!assignment.isSuperseded &&
          assignment.assignmentType != AssignmentType.reflight &&
          assignment.creditedRoundId == credited.id &&
          rounds[assignment.scheduledRoundId]?.isCurrent == true) {
        throw ContestStateError(
          'already_assigned',
          'the pilot already has a flight credited to round '
              '${credited.ordinal}',
        );
      }
    }

    final rows = await _rules.assignmentsOfRound(scheduled);
    final live = _rules.live(rows);
    await _rules.checkSlot(
      contestId: contestId,
      round: scheduled,
      rows: rows,
      group: group,
      lane: lane,
    );
    await _checkGroup(
      round: scheduled,
      rows: rows,
      live: live,
      participationId: participationId,
      group: group,
      lane: lane,
    );
    await _rules.checkTeams(
      contestId: contestId,
      participationId: participationId,
      live: live,
      group: group,
    );

    final lateAdd = MatrixAssignment(
      id: id,
      contestId: contestId,
      matrixRevisionId: scheduled.matrixRevisionId,
      contestParticipationId: participationId,
      scheduledRoundId: scheduled.id,
      creditedRoundId: credited.id,
      group: group,
      lane: lane,
      assignmentType: AssignmentType.lateAdd,
      actorId: actorId,
      reason: reason.trim(),
      createdAt: _clock(),
    );
    final highest = participations.fold<int>(
      0,
      (most, p) => max(most, p.participantNumber ?? 0),
    );
    await repository.matrixAssignmentRepository.addLate(
      lateAdd,
      placeholder: ScorePlaceholder(
        id: _newId(),
        contestId: contestId,
        contestParticipationId: participationId,
        assignmentId: id,
      ),
      numberedParticipation: participation.participantNumber == null
          ? participation.withParticipantNumber(highest + 1)
          : null,
      metadata: metadata,
    );
    return MatrixService(repository).current(contestId);
  }

  Round _currentRound(Map<Id, Round> rounds, Id id) {
    final round = rounds[id];
    if (round == null) {
      throw EntityNotFoundError(entityType: 'Round', entityId: id);
    }
    if (!round.isCurrent) {
      throw ContestStateError(
        'round_not_current',
        'round ${round.ordinal} is no longer current',
      );
    }
    return round;
  }

  Future<void> _checkGroup({
    required Round round,
    required List<MatrixAssignment> rows,
    required List<MatrixAssignment> live,
    required Id participationId,
    required int group,
    required int? lane,
  }) async {
    final inGroup = [
      for (final assignment in live)
        if (assignment.group == group) assignment,
    ];
    if (inGroup.any((a) => a.contestParticipationId == participationId)) {
      throw ContestStateError(
        'already_in_group',
        'the pilot already flies in this group',
      );
    }
    final groups = await repository.roundGroupRepository.listForRound(round.id);
    if (groups.any((g) => g.groupNumber == group && g.isLocked)) {
      throw ContestStateError(
        'group_locked',
        'group $group is locked; unlock it first',
      );
    }
    for (final assignment in inGroup) {
      final placeholder = await repository.scorePlaceholderRepository
          .findForAssignment(assignment.id);
      if (placeholder != null &&
          placeholder.state != ScorePlaceholderState.notEntered) {
        throw ContestStateError(
          'group_already_flown',
          'group $group already has scores; choose a group that has not '
              'flown',
        );
      }
    }
    if (inGroup.length >= _rules.groupCapacity(round, rows)) {
      throw ContestStateError('group_full', 'group $group has no open spot');
    }
    if (lane != null && inGroup.any((a) => a.lane == lane)) {
      throw ContestStateError(
        'lane_taken',
        'lane $lane of group $group is taken by another pilot',
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
