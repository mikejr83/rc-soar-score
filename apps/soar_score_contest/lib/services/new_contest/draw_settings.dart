import 'package:soar_score_core/soar_score_core.dart';

import 'contest_draft.dart';
import 'participant_option.dart';
import 'participant_rules.dart';

/// The step 6 values. Numbers are kept as typed.
///
/// Draw mode, team protection, lane mode and the seeded rounds are saved in
/// the contest configuration. Groups per round, back-to-back flights and
/// the planned rounds are set when the matrix is drawn, so they are kept as
/// a suggestion for the draw (see `contest-options.md`).
class DrawSettings {
  const DrawSettings({
    this.drawMode = DrawMode.standardManOnMan,
    this.groups,
    this.rounds = '8',
    this.laneMode = LaneMode.none,
    this.teamProtection = false,
    this.allowBackToBack = true,
    this.seededRounds = '1',
  });

  final DrawMode drawMode;

  /// Groups per round as typed; `null` uses [GroupPlan.suggestedGroups].
  final String? groups;

  /// The preliminary number of rounds (a planning value).
  final String rounds;

  final LaneMode laneMode;
  final bool teamProtection;
  final bool allowBackToBack;

  /// Man-on-man rounds before seeding starts (seeded mode only).
  final String seededRounds;

  bool get seeded => drawMode == DrawMode.seededManOnMan;

  static const Object _keep = Object();

  DrawSettings copyWith({
    DrawMode? drawMode,
    Object? groups = _keep,
    String? rounds,
    LaneMode? laneMode,
    bool? teamProtection,
    bool? allowBackToBack,
    String? seededRounds,
  }) => DrawSettings(
    drawMode: drawMode ?? this.drawMode,
    groups: identical(groups, _keep) ? this.groups : groups as String?,
    rounds: rounds ?? this.rounds,
    laneMode: laneMode ?? this.laneMode,
    teamProtection: teamProtection ?? this.teamProtection,
    allowBackToBack: allowBackToBack ?? this.allowBackToBack,
    seededRounds: seededRounds ?? this.seededRounds,
  );
}

/// The live group calculation for step 6 and the summary.
class GroupPlan {
  GroupPlan._({
    required this.scoring,
    required this.groups,
    required this.teamProtection,
    required this.largestTeam,
  });

  /// The plan for [draft] with its current draw settings.
  factory GroupPlan.of(ContestDraft draft) {
    final settings = draft.drawSettings;
    final scoring = draft.scoringCount;
    final teamProtection =
        draft.has(ParticipantOption.teams) && settings.teamProtection;
    final largest = draft.largestTeamPilots;
    final typed = settings.groups;
    return GroupPlan._(
      scoring: scoring,
      // Typed text that isn't a number counts as no groups (invalid).
      groups: typed == null
          ? suggestedGroups(scoring, teamProtection ? largest : 1)
          : int.tryParse(typed.trim()) ?? 0,
      teamProtection: teamProtection,
      largestTeam: largest,
    );
  }

  /// A starting value: groups of about 10 pilots, at least [minimum], and
  /// never so many that a group has fewer than 2 pilots.
  static int suggestedGroups(int scoring, int minimum) {
    final most = scoring ~/ 2 < 1 ? 1 : scoring ~/ 2;
    final byTen = (scoring / 10).ceil();
    final suggestion = byTen < minimum ? minimum : byTen;
    return suggestion.clamp(1, most < minimum ? minimum : most);
  }

  final int scoring;

  /// Groups per round (may be invalid, for example 0).
  final int groups;

  final bool teamProtection;

  /// Scoring pilots in the largest team.
  final int largestTeam;

  /// The fewest groups allowed: team protection needs one per pilot of the
  /// largest team.
  int get minGroups => teamProtection && largestTeam > 1 ? largestTeam : 1;

  /// The most groups that still leave every group 2 scoring pilots.
  int get maxGroups => scoring ~/ 2 < 1 ? 1 : scoring ~/ 2;

  int get smallestGroup => groups < 1 ? 0 : scoring ~/ groups;
  int get largestGroup => groups < 1 ? 0 : (scoring / groups).ceil();

  /// The size of each group (at most 12 shown).
  List<int> get sizes => [
    for (var i = 0; i < groups && i < 12; i++)
      scoring ~/ groups + (i < scoring % groups ? 1 : 0),
  ];

  bool get groupsValid => groups >= 1;
  bool get bigEnough => groupsValid && smallestGroup >= 2;
  bool get protectionMet => !teamProtection || groups >= minGroups;

  /// Whether the group settings allow continuing.
  bool get ok => bigEnough && protectionMet;

  /// Whether avoiding back-to-back flights can't work: with fewer than 3
  /// groups a pilot in the last group also flies in the next round's first.
  bool get tooSmallForBackToBack => groups < 3;

  String get perGroupText => smallestGroup == largestGroup
      ? '$smallestGroup'
      : '$smallestGroup–$largestGroup';
}

/// The draw settings in a draft and the team sizes they depend on.
extension DraftDraw on ContestDraft {
  /// Scoring pilots in the largest team (non-pilots don't count).
  int get largestTeamPilots {
    final counts = <String, int>{};
    for (final participant in participants) {
      final team = participant.team.trim().toLowerCase();
      if (team.isNotEmpty && isScoring(participant)) {
        counts[team] = (counts[team] ?? 0) + 1;
      }
    }
    return counts.values.fold(0, (most, n) => n > most ? n : most);
  }
}
