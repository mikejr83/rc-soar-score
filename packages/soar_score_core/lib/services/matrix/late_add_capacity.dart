import '../../enums/lifecycle_state.dart';
import '../../enums/assignment_type.dart';
import '../../errors/contest_state_error.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/round.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/score_placeholder.dart';
import '../../repositories/repository.dart';
import '../contest_scores.dart';
import 'matrix_slot_rules.dart';

/// What stops one group from taking another pilot, or `open` when nothing.
enum GroupVerdict { open, locked, flown, full, teammate }

/// Checks, before a pilot joins a drawn contest, that every round still to
/// be flown has a group that can take them.
///
/// There is no configured group size: a regular group holds `ceil(N / G)`
/// pilots for N original assignments in G groups, so 15 pilots in 4 groups
/// leave one seat in the group of 3, and a 17th pilot with 16 seats fits
/// nowhere. A round that is fully scored never blocks: the pilot is placed
/// there with a zero, as `LatePlacementService` does. A round with no
/// original assignments is not drawn yet and is skipped.
///
/// A group is open when it is not locked, has no score, is below the group
/// capacity and, for a pilot who is already in the contest, holds no
/// teammate under team protection. A lane is not checked: a group below
/// capacity has fewer pilots than the round has lanes, so a lane is always
/// free. Seats are counted after pilots who are in the contest but not
/// seated yet, which errs toward refusing when such a pilot could not take
/// a seat anyway (a teammate, say).
///
/// The check and the save are not one transaction, so two directors adding
/// at once can take the same last seat. The pilot is then added but unseated,
/// which late placement reports and the participants page offers to retry.
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
    final lockedGroups = <Id, Set<int>>{};
    for (final group in await repository.roundGroupRepository.listForContest(
      contestId,
    )) {
      if (group.isLocked) {
        (lockedGroups[group.roundId] ??= {}).add(group.groupNumber);
      }
    }
    final teamProtection =
        (await repository.contestConfigurationRevisionRepository
                .latestForContest(contestId))
            ?.config
            .coreOptions
            .teamProtection ==
        true;
    final teamOf = teamProtection
        ? {
            for (final membership
                in await repository.teamMembershipRepository.listForContest(
                  contestId,
                ))
              membership.contestParticipationId: membership.teamId,
          }
        : const <Id, Id>{};

    for (final round in rounds) {
      final rows = await _rules.assignmentsOfRound(round);
      if (!rows.any((r) => r.assignmentType == AssignmentType.original)) {
        continue;
      }
      final live = _rules.live(rows);
      final progress = RoundProgress.count(
        round,
        live,
        placeholders: placeholders,
        participations: participations,
      );
      if (progress.isComplete) continue;
      final verdicts = _verdicts(
        round,
        rows,
        live,
        placeholders: placeholders,
        locked: lockedGroups[round.id] ?? const {},
        teamOf: teamOf,
        participationId: participationId,
      );
      final openSeats = _openSeats(rows, round, live, verdicts);
      if (openSeats > _waiting(live, participations.values, participationId)) {
        continue;
      }
      throw ContestStateError(
        'no_room_in_round',
        'Round ${round.ordinal} has no group that can take another pilot '
            '(${_describe(verdicts, openSeats, _rules.groupCapacity(round, rows))}). '
            'Raise the number of groups per round and redraw the rounds that '
            'have no scores on the Matrix page, then add the pilot.',
      );
    }
  }

  /// The verdict on each group of [round], by group number.
  Map<int, GroupVerdict> _verdicts(
    Round round,
    List<MatrixAssignment> rows,
    List<MatrixAssignment> live, {
    required Map<Id, ScorePlaceholder> placeholders,
    required Set<int> locked,
    required Map<Id, Id> teamOf,
    required Id? participationId,
  }) {
    final capacity = _rules.groupCapacity(round, rows);
    return {
      for (var group = 1; group <= round.groupCount; group++)
        group: () {
          final inGroup = live.where((a) => a.group == group).toList();
          if (locked.contains(group)) return GroupVerdict.locked;
          if (inGroup.any((a) => _rules.hasFlown(a, placeholders))) {
            return GroupVerdict.flown;
          }
          if (inGroup.length >= capacity) return GroupVerdict.full;
          if (participationId != null &&
              !_rules.teamAllows(
                participationId: participationId,
                live: live,
                group: group,
                teamOf: teamOf,
              )) {
            return GroupVerdict.teammate;
          }
          return GroupVerdict.open;
        }(),
    };
  }

  /// The seats left in the open groups.
  int _openSeats(
    List<MatrixAssignment> rows,
    Round round,
    List<MatrixAssignment> live,
    Map<int, GroupVerdict> verdicts,
  ) {
    final capacity = _rules.groupCapacity(round, rows);
    var seats = 0;
    for (final entry in verdicts.entries) {
      if (entry.value == GroupVerdict.open) {
        seats += capacity - live.where((a) => a.group == entry.key).length;
      }
    }
    return seats;
  }

  /// Pilots in the contest, not retired and not yet seated in the round: they
  /// take the open seats first.
  int _waiting(
    List<MatrixAssignment> live,
    Iterable<ContestParticipation> participations,
    Id? participationId,
  ) {
    final seated = {for (final a in live) a.contestParticipationId};
    return participations
        .where(
          (p) =>
              p.id != participationId &&
              p.isPilot &&
              !p.isRetired &&
              !seated.contains(p.id),
        )
        .length;
  }

  String _describe(
    Map<int, GroupVerdict> verdicts,
    int openSeats,
    int capacity,
  ) {
    int count(GroupVerdict verdict) =>
        verdicts.values.where((v) => v == verdict).length;
    if (openSeats > 0) {
      return '$openSeats open ${openSeats == 1 ? 'seat is' : 'seats are'} '
          'already taken by pilots who are not seated yet';
    }
    return [
      if (count(GroupVerdict.full) > 0)
        '${count(GroupVerdict.full)} full at $capacity pilots',
      if (count(GroupVerdict.flown) > 0)
        '${count(GroupVerdict.flown)} already flown',
      if (count(GroupVerdict.locked) > 0)
        '${count(GroupVerdict.locked)} locked',
      if (count(GroupVerdict.teammate) > 0)
        '${count(GroupVerdict.teammate)} with a teammate',
    ].join(', ');
  }
}
