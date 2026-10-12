import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 17, 14);

/// The matrix page's data for the fixture contest: four scoring pilots and one
/// non-flier, with [matrix] (empty when `null`).
MatrixPageData workspaceData({
  LifecycleState state = LifecycleState.running,
  CurrentMatrix? matrix,
  bool withConfiguration = true,
  List<ContestParticipation>? participations,
  Map<String, Object?> core = const {},
}) => MatrixPageData(
  contest: matrixContest(state: state),
  configuration: withConfiguration ? matrixConfiguration(core) : null,
  participations: participations ?? matrixParticipations(),
  profiles: matrixProfiles(),
  teams: const [],
  memberships: const [],
  matrix: matrix ?? CurrentMatrix(),
);

/// A score slot for [assignment]; official when [setAt] is given.
ScoreSlot scoreSlot(MatrixAssignment assignment, {DateTime? setAt}) {
  final placeholder = ScorePlaceholder(
    id: Id.create(),
    contestId: contestId,
    contestParticipationId: assignment.contestParticipationId,
    assignmentId: assignment.id,
  );
  return ScoreSlot(
    placeholder: placeholder,
    officialScore: setAt == null
        ? null
        : OfficialScore(
            id: Id.create(),
            contestId: contestId,
            scorePlaceholderId: placeholder.id,
            scoreAttemptId: Id.create(),
            scoreRevision: 1,
            components: const {},
            setAt: setAt,
            setBy: Id.create(),
            reason: 'Entered by the director',
          ),
  );
}

/// Scores for [matrix]: every assignment gets a slot; [scoredAt] maps an
/// assignment's (round ordinal, pilot number) to when it was scored.
ContestScores scoresFor(
  CurrentMatrix matrix,
  Map<(int, int), DateTime> scoredAt,
) {
  int pilot(MatrixAssignment a) => [
    for (var n = 1; n <= 5; n++)
      if (participationId(n) == a.contestParticipationId) n,
  ].single;
  int ordinal(MatrixAssignment a) =>
      matrix.rounds.singleWhere((r) => r.id == a.scheduledRoundId).ordinal;
  final slots = [
    for (final a in matrix.assignments)
      scoreSlot(a, setAt: scoredAt[(ordinal(a), pilot(a))]),
  ];
  final rounds = [
    for (final round in matrix.rounds)
      RoundProgress(
        roundId: round.id,
        ordinal: round.ordinal,
        scored: slots
            .where(
              (s) =>
                  s.officialScore != null &&
                  matrix.assignments
                          .singleWhere(
                            (a) => a.id == s.placeholder.assignmentId,
                          )
                          .scheduledRoundId ==
                      round.id,
            )
            .length,
        total: matrix.assignments
            .where((a) => a.scheduledRoundId == round.id)
            .length,
      ),
  ];
  return ContestScores(slots: slots, rounds: rounds);
}

/// [_t0] plus [minutes].
DateTime at(int minutes) => _t0.add(Duration(minutes: minutes));

/// [matrix] with [old] superseded by a copy of it moved to [group] of the
/// same round.
CurrentMatrix moveAssignment(
  CurrentMatrix matrix,
  MatrixAssignment old,
  int group,
) {
  final moved = MatrixAssignment(
    id: Id.create(),
    contestId: contestId,
    matrixRevisionId: old.matrixRevisionId,
    contestParticipationId: old.contestParticipationId,
    scheduledRoundId: old.scheduledRoundId,
    creditedRoundId: old.creditedRoundId,
    group: group,
    assignmentType: AssignmentType.moved,
    sourceAssignmentId: old.id,
    actorId: old.actorId,
    reason: 'Moved by the director',
    createdAt: old.createdAt,
  );
  final superseded = MatrixAssignment(
    id: old.id,
    contestId: contestId,
    matrixRevisionId: old.matrixRevisionId,
    contestParticipationId: old.contestParticipationId,
    scheduledRoundId: old.scheduledRoundId,
    creditedRoundId: old.creditedRoundId,
    group: old.group,
    assignmentType: AssignmentType.original,
    supersededByAssignmentId: moved.id,
    actorId: old.actorId,
    createdAt: old.createdAt,
  );
  return CurrentMatrix(
    revision: matrix.revision,
    rounds: matrix.rounds,
    groups: matrix.groups,
    assignments: [
      for (final a in matrix.assignments) a.id == old.id ? superseded : a,
      moved,
    ],
    progress: matrix.progress,
  );
}
