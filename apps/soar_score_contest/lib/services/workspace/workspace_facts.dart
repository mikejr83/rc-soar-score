import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../configuration/configuration_problem.dart';
import '../configuration/discipline_label.dart';
import '../configuration/draw_readiness.dart';
import '../configuration/house_rules.dart';
import '../matrix/config_drift.dart';
import '../matrix/matrix_page_data.dart';
import '../matrix/round_progress_view.dart';
import 'current_group_facts.dart';
import 'latest_score.dart';
import 'participant_number_range.dart';
import 'publication_facts.dart';
import 'transition_facts.dart';
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
    required this.disciplineLabel,
    required this.landingTableName,
    required this.houseRuleCount,
    required this.participantNumbers,
    required this.matrix,
    required this.roundCount,
    required this.groupCount,
    required this.groupSizeMin,
    required this.groupSizeMax,
    required this.rounds,
    required this.latestScore,
    required this.currentGroup,
    required this.frontierGroup,
    required this.scoreCount,
    required this.configDrift,
    required this.drawReadiness,
    required this.publication,
    required this.transitions,
    required this.unavailable,
    required this.isOffline,
  });

  /// Reduces [data] (the matrix page's data for [data.contest]), the optional
  /// [scores], the [publication] and the audit [transitions] to facts.
  ///
  /// [scores] is `null` when that read failed, in which case [unavailable]
  /// should list [WorkspaceFactSource.scores]. The same holds for
  /// [landingTables] and [WorkspaceFactSource.landingTables].
  factory WorkspaceFacts.derive({
    required MatrixPageData data,
    ContestScores? scores,
    List<LandingTableView>? landingTables,
    PublicationFacts publication = PublicationFacts.unknown,
    TransitionFacts transitions = TransitionFacts.unknown,
    Set<WorkspaceFactSource> unavailable = const {},
    bool isOffline = false,
  }) {
    final matrix = data.matrix;
    final options = data.options;
    final profile = _systemProfile(data.configuration);
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
            groupCount: round.groupCount,
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

    // The frontier is the latest round, by ordinal, that has a score. A
    // correction to an earlier round makes the latest score by time sit
    // behind it, so the group the progress card shows is found separately.
    final frontier = rounds
        .where((round) => round.scored > 0)
        .fold<int?>(
          null,
          (most, round) =>
              most == null || round.ordinal > most ? round.ordinal : most,
        );
    final frontierScore = scores == null || frontier == null
        ? null
        : _latestScore(
            scores,
            assignments,
            roundById,
            onlyRoundOrdinal: frontier,
          );
    final assignmentIds = {for (final a in assignments) a.id};
    return WorkspaceFacts._(
      contest: data.contest,
      configuration: data.configuration,
      options: options,
      configurationProblem: problem,
      scoringPilots: data.scoringPilots,
      teamCount: data.teams.length,
      onlyPilotName: data.scoringPilots == 1 ? _onlyPilotName(data) : null,
      disciplineLabel: profile == null
          ? null
          : DisciplineLabel.of(profile.profile),
      landingTableName: _landingTableName(
        data.configuration?.landingTableId,
        landingTables,
      ),
      houseRuleCount: HouseRules.ofRevision(data.configuration, profile),
      participantNumbers: ParticipantNumberRange.of(data.participations),
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
      frontierGroup: frontierScore == null || scores == null
          ? null
          : _currentGroup(frontierScore, scores, assignments, roundById, sizes),
      scoreCount: scores == null
          ? 0
          : scores.slots
                .where(
                  (slot) =>
                      slot.officialScore != null &&
                      assignmentIds.contains(slot.placeholder.assignmentId),
                )
                .length,
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
      transitions: transitions,
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
          disciplineLabel: disciplineLabel,
          landingTableName: landingTableName,
          houseRuleCount: houseRuleCount,
          participantNumbers: participantNumbers,
          matrix: matrix,
          roundCount: roundCount,
          groupCount: groupCount,
          groupSizeMin: groupSizeMin,
          groupSizeMax: groupSizeMax,
          rounds: rounds,
          latestScore: latestScore,
          currentGroup: currentGroup,
          frontierGroup: frontierGroup,
          scoreCount: scoreCount,
          configDrift: configDrift,
          drawReadiness: drawReadiness,
          publication: publication,
          transitions: transitions,
          unavailable: unavailable,
          isOffline: isOffline,
        );

  /// The bundled profile the configuration is for; `null` without a
  /// configuration or for a profile that is not a system one.
  static DisciplineProfileWithRules? _systemProfile(
    ContestConfigurationRevision? configuration,
  ) {
    if (configuration == null) {
      return null;
    }
    for (final profile in SystemDisciplineProfiles.all) {
      if (profile.profile.id == configuration.disciplineProfileId) {
        return profile;
      }
    }
    return null;
  }

  static String? _landingTableName(
    Id? id,
    List<LandingTableView>? landingTables,
  ) {
    if (id == null || landingTables == null) {
      return null;
    }
    for (final view in landingTables) {
      if (view.table.id == id) {
        return view.table.name;
      }
    }
    return null;
  }

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
    Map<Id, Round> roundById, {
    int? onlyRoundOrdinal,
  }) {
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
      if (onlyRoundOrdinal != null &&
          roundById[assignment.scheduledRoundId]!.ordinal != onlyRoundOrdinal) {
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

  /// The discipline's name as the wizard shows it (`F5J`); `null` without a
  /// configuration or for a profile that is not a system one.
  final String? disciplineLabel;

  /// The saved configuration's landing table; `null` without a configuration
  /// or table, or when the landing tables could not be read.
  final String? landingTableName;

  /// Discipline options that differ from the profile's official values.
  final int houseRuleCount;

  /// The participant numbers handed out; `null` before the first draw.
  final ParticipantNumberRange? participantNumbers;

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

  /// The group of the latest score within the latest round that has a score
  /// (the progress card's "current group"). It differs from [currentGroup]
  /// when an earlier round's score was corrected most recently.
  final CurrentGroupFacts? frontierGroup;

  /// How many slots of the current matrix have an official score.
  final int scoreCount;

  /// Settings that differ from those the matrix was drawn with.
  final List<String> configDrift;
  final DrawReadiness drawReadiness;
  final PublicationFacts publication;

  /// Completion and lock facts from the audit trail; see [completedAt].
  final TransitionFacts transitions;

  /// Secondary reads that failed.
  final Set<WorkspaceFactSource> unavailable;
  final bool isOffline;

  bool get hasMatrix => !matrix.isEmpty;

  /// Whether a read the next-step card depends on failed. The landing-table
  /// read feeds only the setup checklist, so it does not count here.
  bool get nextStepFactsUnavailable =>
      unavailable.contains(WorkspaceFactSource.scores) ||
      unavailable.contains(WorkspaceFactSource.publication);

  DrawMode? get drawMode => options?.drawMode;
  int? get intendedTotalRounds => options?.intendedTotalRounds;

  /// From the audit trail (#345); `null` when it holds no such event or could
  /// not be read.
  DateTime? get completedAt => transitions.completedAt;
  DateTime? get lockedAt => transitions.lockedAt;
  String? get lockedBy => transitions.lockedBy;

  @override
  List<Object?> get props => [
    contest,
    configuration,
    configurationProblem,
    scoringPilots,
    teamCount,
    onlyPilotName,
    disciplineLabel,
    landingTableName,
    houseRuleCount,
    participantNumbers,
    matrix,
    roundCount,
    groupCount,
    groupSizeMin,
    groupSizeMax,
    rounds,
    latestScore,
    currentGroup,
    frontierGroup,
    scoreCount,
    configDrift,
    publication,
    transitions,
    unavailable,
    isOffline,
  ];
}
