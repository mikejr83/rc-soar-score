import 'dart:math';

import '../../enums/assignment_type.dart';
import '../../enums/draw_mode.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/matrix_draw.dart';
import '../../models/matrix/matrix_revision.dart';
import '../../models/matrix/round.dart';
import '../../models/matrix/round_group.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/score_placeholder.dart';
import 'basic_draw.dart';

/// A finalized draw as the models that store it, with the score placeholders
/// of its assignments.
class BuiltDraw {
  BuiltDraw({required this.draw, required this.placeholders});

  final MatrixDraw draw;

  /// One placeholder for each `Original` assignment.
  final List<ScorePlaceholder> placeholders;
}

/// Turns the groups an engine drew into a finalized revision with its rounds,
/// groups, assignments and score placeholders.
class MatrixDrawBuilder {
  MatrixDrawBuilder({required this.newId});

  final Id Function() newId;

  /// The revision [id] of [contestId], whose rounds are [drawn] (the first of
  /// them is round [firstRound]).
  ///
  /// [drawConfig] adds to the stored draw settings (`groups_per_round`, the
  /// seed, the options the draw used); [previousRevisionId] is the revision a
  /// later draw continues. A seeded draw passes [drawMode] and the
  /// [seedingStandings] it was tiered by, stored in the seeding snapshot.
  BuiltDraw build({
    required Id contestId,
    required Id id,
    required int revisionNumber,
    Id? previousRevisionId,
    required int firstRound,
    required List<List<List<DrawSlot>>> drawn,
    required int seed,
    required String algorithmVersion,
    required int groupsPerRound,
    required Map<String, Object?> drawConfig,
    required List<DrawPilot> pilots,
    required Map<String, Object?> fairness,
    required String reason,
    required Id actorId,
    required DateTime now,
    DrawMode drawMode = DrawMode.standardManOnMan,
    Map<String, Object?>? seedingStandings,
  }) {
    final revision = MatrixRevision(
      id: id,
      contestId: contestId,
      revisionNumber: revisionNumber,
      previousRevisionId: previousRevisionId,
      firstRound: firstRound,
      lastRound: firstRound + drawn.length - 1,
      drawMode: drawMode,
      randomSeed: seed,
      algorithmVersion: algorithmVersion,
      drawConfig: {'groups_per_round': groupsPerRound, ...drawConfig},
      seedingSnapshot: {
        'pilots': [
          for (final pilot in pilots)
            {
              'participation_id': pilot.participationId.value,
              'team_id': pilot.teamId?.value,
            },
        ],
        'standings': ?seedingStandings,
      },
      fairnessSummary: fairness,
      reason: reason,
      createdBy: actorId,
      createdAt: now,
      finalizedBy: actorId,
      finalizedAt: now,
    );

    final rounds = <Round>[];
    final groups = <RoundGroup>[];
    final assignments = <MatrixAssignment>[];
    final placeholders = <ScorePlaceholder>[];
    for (var r = 0; r < drawn.length; r++) {
      final round = Round(
        id: newId(),
        contestId: contestId,
        matrixRevisionId: id,
        ordinal: firstRound + r,
        groupCount: groupsPerRound,
      );
      rounds.add(round);
      for (var g = 0; g < drawn[r].length; g++) {
        groups.add(
          RoundGroup(
            id: newId(),
            contestId: contestId,
            roundId: round.id,
            groupNumber: g + 1,
          ),
        );
        for (final slot in drawn[r][g]) {
          final assignment = MatrixAssignment(
            id: newId(),
            contestId: contestId,
            matrixRevisionId: id,
            contestParticipationId: slot.pilot.participationId,
            scheduledRoundId: round.id,
            creditedRoundId: round.id,
            group: g + 1,
            lane: slot.lane,
            assignmentType: AssignmentType.original,
            actorId: actorId,
            createdAt: now,
          );
          assignments.add(assignment);
          placeholders.add(
            ScorePlaceholder(
              id: newId(),
              contestId: contestId,
              contestParticipationId: slot.pilot.participationId,
              assignmentId: assignment.id,
            ),
          );
        }
      }
    }
    return BuiltDraw(
      draw: MatrixDraw(
        revision: revision,
        rounds: rounds,
        groups: groups,
        assignments: assignments,
      ),
      placeholders: placeholders,
    );
  }

  /// The participations of [participations] that have no number, with the
  /// next numbers in the order they were added (one running sequence).
  static List<ContestParticipation> numbered(
    List<ContestParticipation> participations,
  ) {
    var next =
        participations.fold<int>(
          0,
          (highest, p) => max(highest, p.participantNumber ?? 0),
        ) +
        1;
    return [
      for (final p in participations)
        if (p.participantNumber == null) p.withParticipantNumber(next++),
    ];
  }
}
