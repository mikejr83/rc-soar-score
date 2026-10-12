import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../configuration/configuration_problem.dart';
import '../configuration/draw_readiness.dart';
import '../matrix/config_drift.dart';
import '../matrix/matrix_page_data.dart';
import '../matrix/round_progress_view.dart';
import 'current_group_facts.dart';
import 'latest_score.dart';
import 'publication_facts.dart';
import 'workspace_fact_source.dart';
import 'workspace_round_fact.dart';

/// Everything the workspace's next-step card reads about one contest, reduced
/// to plain values so the resolver (#343) stays a pure function.
///
/// Built from data the matrix page already loads plus the scores and
/// publication reads; the rules (draw readiness, configuration drift, round
/// progress) are the existing ones, not copies.
class WorkspaceFacts extends Equatable {
  const WorkspaceFacts._({
    required this.contest,
    required this.configuration,
    required this.options,
    required this.configurationProblem,
    required this.scoringPilots,
    required this.teamCount,
    required this.onlyPilotName,
    required this.matrix,
    required this.roundCount,
    required this.groupCount,
    required this.groupSizeMin,
    required this.groupSizeMax,
    required this.rounds,
    required this.latestScore,
    required this.currentGroup,
    required this.configDrift,
    required this.drawReadiness,
    required this.publication,
    required this.unavailable,
    required this.isOffline,
  });

  /// Reduces [data] (the matrix page's data for [data.contest]), the optional
  /// [scores] and the [publication] to facts.
  ///
  /// [scores] is `null` when that read failed, in which case [unavailable]
  /// should list [WorkspaceFactSource.scores].
  factory WorkspaceFacts.derive({
    required MatrixPageData data,
    ContestScores? scores,
    PublicationFacts publication = PublicationFacts.unknown,
    Set<WorkspaceFactSource> unavailable = const {},
    bool isOffline = false,
  }) {
    final matrix = data.matrix;
    final options = data.options;
    final problem = ConfigurationProblem.of(
      configuration: data.configuration,
      options: options,
    );
    final activeRounds = [
      for (final round in matrix.rounds)
        if (round.supersededByRoundId == null) round,
    ]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final liveRounds = [
      for (final round in activeRounds)
        if (round.status != RoundStatus.cancelled) round,
    ];
    final roundById = {for (final round in activeRounds) round.id: round};
    final assignments = [
      for (final assignment in matrix.assignments)
        if (!assignment.isSuperseded &&
            roundById[assignment.scheduledRoundId] != null &&
            roundById[assignment.scheduledRoundId]!.status !=
                RoundStatus.cancelled)
          assignment,
    ];

    final sizes = <(Id, int), int>{};
    for (final assignment in assignments) {
      final key = (assignment.scheduledRoundId, assignment.group);
      sizes[key] = (sizes[key] ?? 0) + 1;
    }

    final rounds = <WorkspaceRoundFact>[];
    if (scores != null) {
      final progress = {for (final item in scores.rounds) item.roundId: item};
      for (final round in liveRounds) {
        final item = progress[round.id];
        final scored = item?.scored ?? 0;
        final total = item?.total ?? 0;
        rounds.add(
          WorkspaceRoundFact(
            ordinal: round.ordinal,
            scored: scored,
            total: total,
            state: RoundProgressView.of(
              round.status,
              scored: scored,
              total: total,
            ).state,
          ),
        );
      }
    }

    final latest = scores == null
        ? null
        : _latestScore(scores, assignments, roundById);
    return WorkspaceFacts._(
      contest: data.contest,
      configuration: data.configuration,
      options: options,
      configurationProblem: problem,
      scoringPilots: data.scoringPilots,
      teamCount: data.teams.length,
      onlyPilotName: data.scoringPilots == 1 ? _onlyPilotName(data) : null,
      matrix: matrix,
      roundCount: liveRounds.length,
      groupCount: liveRounds.fold(
        0,
        (most, round) => round.groupCount > most ? round.groupCount : most,
      ),
      groupSizeMin: sizes.isEmpty
          ? 0
          : sizes.values.reduce((a, b) => a < b ? a : b),
      groupSizeMax: sizes.isEmpty
          ? 0
          : sizes.values.reduce((a, b) => a > b ? a : b),
      rounds: List.unmodifiable(rounds),
      latestScore: latest?.$1,
      currentGroup: latest == null || scores == null
          ? null
          : _currentGroup(latest, scores, assignments, roundById, sizes),
      configDrift: matrix.revision == null
          ? const []
          : ConfigDrift.differences(
              revision: matrix.revision!,
              options: options,
            ),
      drawReadiness: DrawReadiness.evaluate(
        contest: data.contest,
        configurationProblem: problem,
        scoringPilots: data.scoringPilots,
        matrixDrawn: !matrix.isEmpty,
      ),
      publication: publication,
      unavailable: Set.unmodifiable(unavailable),
      isOffline: isOffline,
    );
  }

  /// These facts with [isOffline] replaced, so the connectivity monitor's
  /// changes reach the cards without loading anything again.
  WorkspaceFacts withOffline(bool isOffline) => this.isOffline == isOffline
      ? this
      : WorkspaceFacts._(
          contest: contest,
          configuration: configuration,
          options: options,
          configurationProblem: configurationProblem,
          scoringPilots: scoringPilots,
          teamCount: teamCount,
          onlyPilotName: onlyPilotName,
          matrix: matrix,
          roundCount: roundCount,
          groupCount: groupCount,
          groupSizeMin: groupSizeMin,
          groupSizeMax: groupSizeMax,
          rounds: rounds,
          latestScore: latestScore,
          currentGroup: currentGroup,
          configDrift: configDrift,
          drawReadiness: drawReadiness,
          publication: publication,
          unavailable: unavailable,
          isOffline: isOffline,
        );

  static String? _onlyPilotName(MatrixPageData data) {
    for (final participation in data.participations) {
      if (participation.roleType == RoleType.pilot &&
          participation.retiredAtRound == null) {
        return data.pilots[participation.id]?.name;
      }
    }
    return null;
  }

  /// The score with the largest `setAt`, with the assignment it belongs to.
  /// Scores of superseded or cancelled-round assignments are ignored.
  static (LatestScore, MatrixAssignment)? _latestScore(
    ContestScores scores,
    List<MatrixAssignment> assignments,
    Map<Id, Round> roundById,
  ) {
    final byId = {
      for (final assignment in assignments) assignment.id: assignment,
    };
    OfficialScore? best;
    MatrixAssignment? bestAssignment;
    for (final slot in scores.slots) {
      final score = slot.officialScore;
      final assignment = byId[slot.placeholder.assignmentId];
      if (score == null || assignment == null) {
        continue;
      }
      if (best == null || score.setAt.isAfter(best.setAt)) {
        best = score;
        bestAssignment = assignment;
      }
    }
    if (best == null || bestAssignment == null) {
      return null;
    }
    final round = roundById[bestAssignment.scheduledRoundId]!;
    return (
      LatestScore(
        roundOrdinal: round.ordinal,
        groupNumber: bestAssignment.group,
        setAt: best.setAt,
      ),
      bestAssignment,
    );
  }

  static CurrentGroupFacts _currentGroup(
    (LatestScore, MatrixAssignment) latest,
    ContestScores scores,
    List<MatrixAssignment> assignments,
    Map<Id, Round> roundById,
    Map<(Id, int), int> sizes,
  ) {
    final (score, assignment) = latest;
    final roundId = assignment.scheduledRoundId;
    final inGroup = {
      for (final other in assignments)
        if (other.scheduledRoundId == roundId &&
            other.group == score.groupNumber)
          other.id,
    };
    final scored = scores.slots
        .where(
          (slot) =>
              slot.officialScore != null &&
              inGroup.contains(slot.placeholder.assignmentId),
        )
        .length;
    final laterGroups = [
      for (final key in sizes.keys)
        if (key.$1 == roundId && key.$2 > score.groupNumber) key.$2,
    ]..sort();
    int? nextRound;
    int? nextGroup;
    if (laterGroups.isNotEmpty) {
      nextRound = score.roundOrdinal;
      nextGroup = laterGroups.first;
    } else {
      final later = [
        for (final round in roundById.values)
          if (round.ordinal > score.roundOrdinal &&
              round.status != RoundStatus.cancelled)
            round.ordinal,
      ]..sort();
      if (later.isNotEmpty) {
        nextRound = later.first;
        nextGroup = 1;
      }
    }
    return CurrentGroupFacts(
      roundOrdinal: score.roundOrdinal,
      groupNumber: score.groupNumber,
      scored: scored,
      total: inGroup.length,
      nextRoundOrdinal: nextRound,
      nextGroupNumber: nextGroup,
    );
  }

  final Contest contest;

  /// The latest saved configuration, or `null` when none is saved.
  final ContestConfigurationRevision? configuration;

  /// The contest options, or `null` when none are saved or they are invalid.
  final CoreOptions? options;

  /// What is wrong with the configuration, or `null` when it is usable.
  final String? configurationProblem;

  /// Pilots who fly: not non-fliers, not retired.
  final int scoringPilots;
  final int teamCount;

  /// The pilot's name when [scoringPilots] is 1.
  final String? onlyPilotName;

  /// The current matrix; empty before the first draw.
  final CurrentMatrix matrix;
  final int roundCount;
  final int groupCount;
  final int groupSizeMin;
  final int groupSizeMax;

  /// Each uncancelled round's progress; empty when scores are unavailable.
  final List<WorkspaceRoundFact> rounds;
  final LatestScore? latestScore;
  final CurrentGroupFacts? currentGroup;

  /// Settings that differ from those the matrix was drawn with.
  final List<String> configDrift;
  final DrawReadiness drawReadiness;
  final PublicationFacts publication;

  /// Secondary reads that failed.
  final Set<WorkspaceFactSource> unavailable;
  final bool isOffline;

  bool get hasMatrix => !matrix.isEmpty;

  DrawMode? get drawMode => options?.drawMode;
  int? get intendedTotalRounds => options?.intendedTotalRounds;

  /// Placeholders for the audit trail (#345), which supplies them.
  DateTime? get completedAt => null;
  DateTime? get lockedAt => null;
  String? get lockedBy => null;

  @override
  List<Object?> get props => [
    contest,
    configuration,
    configurationProblem,
    scoringPilots,
    teamCount,
    onlyPilotName,
    matrix,
    roundCount,
    groupCount,
    groupSizeMin,
    groupSizeMax,
    rounds,
    latestScore,
    currentGroup,
    configDrift,
    publication,
    unavailable,
    isOffline,
  ];
}
