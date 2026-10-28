import 'package:equatable/equatable.dart';

import '../../enums/lane_mode.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/round.dart';
import '../../models/participants/contest_participation.dart';
import '../../repositories/mutation_metadata.dart';
import '../../repositories/repository.dart';
import '../contest_scores.dart';
import '../scores_service.dart';
import 'late_add_service.dart';
import 'matrix_slot_rules.dart';

/// What happened to one round when a pilot was placed in every round.
class RoundPlacement extends Equatable {
  const RoundPlacement({
    required this.round,
    this.group,
    this.lane,
    this.zeroed = false,
    this.alreadyPlaced = false,
    this.skippedReason,
  });

  factory RoundPlacement.fromJson(Map<String, Object?> json) => RoundPlacement(
    round: json['round']! as int,
    group: json['group'] as int?,
    lane: json['lane'] as int?,
    zeroed: json['zeroed'] as bool? ?? false,
    alreadyPlaced: json['already_placed'] as bool? ?? false,
    skippedReason: json['skipped_reason'] as String?,
  );

  /// The round's ordinal.
  final int round;

  /// The group and lane the pilot was put in; `null` for a round that was
  /// skipped or where the pilot already flew.
  final int? group;
  final int? lane;

  /// The round was already fully scored, so the pilot got a zero in it.
  final bool zeroed;

  /// The pilot already had a flight in the round; nothing was added.
  final bool alreadyPlaced;

  /// Why no group could take the pilot, if none could.
  final String? skippedReason;

  bool get placed => group != null;

  Map<String, Object?> toJson() => {
    'round': round,
    'group': group,
    'lane': lane,
    'zeroed': zeroed,
    'already_placed': alreadyPlaced,
    'skipped_reason': skippedReason,
  };

  @override
  List<Object?> get props => [
    round,
    group,
    lane,
    zeroed,
    alreadyPlaced,
    skippedReason,
  ];
}

/// Puts a pilot who joined after the draw into every round of the current
/// matrix, in the last group that can take them.
///
/// A round that is not fully scored gets a normal late add, trying the last
/// group first and going back to earlier ones when a group is full, locked,
/// has flown or holds a teammate (team protection). A round that is fully
/// scored cannot be flown again, so the pilot is added to its last group and
/// receives a zero, which the director can correct. A round no group can take
/// the pilot in is reported, not failed: the director places them from the
/// Matrix page.
class LatePlacementService {
  LatePlacementService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _lateAdds = LateAddService(repository, clock: clock, newId: newId),
       _scores = ScoresService(repository, clock: clock, newId: newId),
       _newId = newId ?? Id.create;

  final Repository repository;
  final LateAddService _lateAdds;
  final ScoresService _scores;
  final Id Function() _newId;
  late final _rules = MatrixSlotRules(repository);

  /// The official score a pilot receives for a round flown before they joined:
  /// a blank entry, which every discipline scores as an ordinary zero.
  static const Map<String, Object?> zeroComponents = {};

  static const _retryable = {
    'group_full',
    'group_already_flown',
    'group_locked',
    'team_conflict',
    'lane_taken',
    'already_in_group',
  };

  /// Places participation [participationId] of contest [contestId] in every
  /// current round. Repeating the call places nobody twice: a round the pilot
  /// already flies is reported as placed already.
  ///
  /// Throws what [LateAddService.add] throws for the contest and the pilot
  /// (no matrix to edit, locked, completed, not a pilot, retired).
  Future<List<RoundPlacement>> placeInAllRounds(
    Id contestId,
    Id participationId, {
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
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
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where((round) => round.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    if (rounds.isEmpty) {
      throw ContestStateError(
        'no_matrix',
        'the contest has no matrix to add a pilot to',
      );
    }
    final laneMode =
        (await repository.contestConfigurationRevisionRepository
                .latestForContest(contestId))
            ?.config
            .coreOptions
            .laneMode;

    final results = <RoundPlacement>[];
    for (final round in rounds) {
      results.add(
        await _placeInRound(
          contestId,
          participation,
          participations,
          round,
          laneMode: laneMode ?? LaneMode.none,
          actorId: actorId,
          metadata: metadata,
        ),
      );
    }
    return results;
  }

  Future<RoundPlacement> _placeInRound(
    Id contestId,
    ContestParticipation participation,
    List<ContestParticipation> participations,
    Round round, {
    required LaneMode laneMode,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final rows = await _rules.assignmentsOfRound(round);
    final live = _rules.live(rows);
    if (live.any((a) => a.contestParticipationId == participation.id)) {
      return RoundPlacement(round: round.ordinal, alreadyPlaced: true);
    }
    final placeholders = {
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        placeholder.assignmentId: placeholder,
    };
    final progress = RoundProgress.count(
      round,
      live,
      placeholders: placeholders,
      participations: {for (final p in participations) p.id: p},
    );
    final scored = progress.isComplete;

    String? lastReason;
    for (var group = round.groupCount; group >= 1; group--) {
      final lane = laneMode == LaneMode.none
          ? null
          : _freeLane(rows, live, group);
      final id = _newId();
      try {
        await _lateAdds.add(
          contestId,
          id: id,
          participationId: participation.id,
          scheduledRoundId: round.id,
          group: group,
          lane: lane,
          reason: scored
              ? 'Added after the round was scored'
              : 'Added after the draw',
          actorId: actorId,
          // One request places the pilot in several rounds; each write keeps
          // its own mutation id, or the store rejects the second.
          metadata: metadata.forPart('placement-${round.id.value}'),
          flownRound: scored,
        );
      } on ContestStateError catch (error) {
        if (!_retryable.contains(error.code)) rethrow;
        lastReason = error.message;
        continue;
      }
      if (scored) {
        await _scores.enterOfficialScore(
          contestId,
          id,
          clientMutationId: 'late-zero-${id.value}',
          baseScoreRevision: 0,
          components: zeroComponents,
          reason: 'Added after the round was scored',
          actorId: actorId,
          metadata: metadata.forPart('placement-zero-${round.id.value}'),
        );
      }
      return RoundPlacement(
        round: round.ordinal,
        group: group,
        lane: lane,
        zeroed: scored,
      );
    }
    return RoundPlacement(
      round: round.ordinal,
      skippedReason: lastReason ?? 'no group could take the pilot',
    );
  }

  /// The lowest lane number nobody flies in [group], or the highest lane when
  /// every one is taken (a flown round does not check lanes).
  int _freeLane(
    List<MatrixAssignment> rows,
    List<MatrixAssignment> live,
    int group,
  ) {
    final size = _rules.capacity(rows);
    final taken = {
      for (final a in live)
        if (a.group == group && a.lane != null) a.lane!,
    };
    for (var lane = 1; lane <= size; lane++) {
      if (!taken.contains(lane)) return lane;
    }
    return size;
  }
}
