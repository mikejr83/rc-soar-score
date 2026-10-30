import '../../enums/lifecycle_state.dart';
import '../../enums/score_placeholder_state.dart';
import '../../errors/contest_state_error.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/round.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/score_placeholder.dart';
import '../../repositories/repository.dart';
import '../contest_scores.dart';
import 'matrix_slot_rules.dart';

/// Checks, before a pilot joins a drawn contest, that every round still to
/// be flown has a group that can take them.
///
/// There is no configured group size: a regular group holds `ceil(N / G)`
/// pilots for N original assignments in G groups, so 15 pilots in 4 groups
/// leave one seat in the group of 3, and a 17th pilot with 16 seats fits
/// nowhere. A round that is fully scored never blocks: the pilot is placed
/// there with a zero, as `LatePlacementService` does.
class LateAddCapacity {
  LateAddCapacity(this.repository);

  final Repository repository;
  late final _rules = MatrixSlotRules(repository);

  /// Throws a [ContestStateError] (`no_room_in_round`) naming the first
  /// round that is not fully scored and where no group can take a pilot.
  ///
  /// [participationId] is the pilot who is joining, when they already exist
  /// (a non-flier becoming a pilot), so a teammate in a group can count
  /// against it. A contest that is not drawn, or is not Ready or Running, has
  /// nothing to check.
  Future<void> requireRoomForPilot(Id contestId, {Id? participationId}) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null ||
        (contest.lifecycleState != LifecycleState.ready &&
            contest.lifecycleState != LifecycleState.running)) {
      return;
    }
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where((round) => round.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    if (rounds.isEmpty) return;
    final participations = {
      for (final p
          in await repository.contestParticipationRepository.listForContest(
            contestId,
          ))
        p.id: p,
    };
    final placeholders = {
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        placeholder.assignmentId: placeholder,
    };
    for (final round in rounds) {
      final rows = await _rules.assignmentsOfRound(round);
      final live = _rules.live(rows);
      final progress = RoundProgress.count(
        round,
        live,
        placeholders: placeholders,
        participations: participations,
      );
      if (progress.isComplete) continue;
      final refusal = await _refusal(
        contestId,
        round,
        rows,
        live,
        placeholders,
        participationId,
        participations.values,
      );
      if (refusal != null) {
        throw ContestStateError(
          'no_room_in_round',
          'Round ${round.ordinal} has no group that can take another pilot '
              '($refusal). Raise the number of groups per round and redraw '
              'the rounds that have no scores on the Matrix page, then add '
              'the pilot.',
        );
      }
    }
  }

  /// Why no group of [round] can take a pilot, or null when one can.
  Future<String?> _refusal(
    Id contestId,
    Round round,
    List<MatrixAssignment> rows,
    List<MatrixAssignment> live,
    Map<Id, ScorePlaceholder> placeholders,
    Id? participationId,
    Iterable<ContestParticipation> participations,
  ) async {
    // Pilots already in the contest and not yet seated in this round take
    // the open seats first, so a pilot just added does not count twice.
    final seated = {for (final a in live) a.contestParticipationId};
    final waiting = participations
        .where(
          (p) =>
              p.id != participationId &&
              p.isPilot &&
              !p.isRetired &&
              !seated.contains(p.id),
        )
        .length;
    final capacity = _rules.groupCapacity(round, rows);
    final locked = {
      for (final group in await repository.roundGroupRepository.listForRound(
        round.id,
      ))
        if (group.isLocked) group.groupNumber,
    };
    var openSeats = 0;
    var full = 0;
    var flown = 0;
    var lockedCount = 0;
    var teammates = 0;
    for (var group = 1; group <= round.groupCount; group++) {
      final inGroup = live.where((a) => a.group == group).toList();
      if (locked.contains(group)) {
        lockedCount++;
        continue;
      }
      if (inGroup.any(
        (a) => switch (placeholders[a.id]?.state) {
          null || ScorePlaceholderState.notEntered => false,
          _ => true,
        },
      )) {
        flown++;
        continue;
      }
      if (inGroup.length >= capacity) {
        full++;
        continue;
      }
      if (participationId != null) {
        try {
          await _rules.checkTeams(
            contestId: contestId,
            participationId: participationId,
            live: live,
            group: group,
          );
        } on ContestStateError {
          teammates++;
          continue;
        }
      }
      openSeats += capacity - inGroup.length;
      if (openSeats > waiting) return null;
    }
    if (openSeats > 0) {
      return '$openSeats open ${openSeats == 1 ? 'seat is' : 'seats are'} '
          'already taken by pilots who are not seated yet';
    }
    return [
      if (full > 0) '$full full at $capacity pilots',
      if (flown > 0) '$flown already flown',
      if (lockedCount > 0) '$lockedCount locked',
      if (teammates > 0) '$teammates with a teammate',
    ].join(', ');
  }
}
