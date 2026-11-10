import '../models/contest/contest_configuration_revision.dart';
import '../enums/assignment_type.dart';
import '../models/id.dart';
import '../models/matrix/matrix_assignment.dart';
import '../models/matrix/round.dart';
import '../models/participants/contest_participation.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_attempt.dart';
import '../models/scores/score_placeholder.dart';
import '../repositories/repository.dart';
import '../scoring/recalculation/f5j_contest_input.dart';
import '../scoring/standings/team_entry.dart';
import 'landing_bonus.dart';

/// One scored flight of the current matrix, with the rows it came from.
///
/// A flight is scored by its official score, or, only when the input is
/// built with participant attempts, by the pilot's newest submitted attempt
/// (a preliminary score).
class ScoredSlot {
  const ScoredSlot({
    required this.round,
    required this.assignment,
    required this.placeholder,
    this.officialScore,
    this.attempt,
  }) : assert(
         (officialScore == null) != (attempt == null),
         'a scored flight has an official score or a preliminary attempt',
       );

  final Round round;
  final MatrixAssignment assignment;
  final ScorePlaceholder placeholder;

  /// Null when the flight is scored by [attempt] only.
  final OfficialScore? officialScore;

  /// The attempt a preliminary score comes from; null for an official one.
  final ScoreAttempt? attempt;

  /// True when no official score exists and the flight counts on a pilot's
  /// submitted attempt.
  bool get isPreliminary => officialScore == null;

  Map<String, Object?> get components =>
      officialScore?.components ?? attempt!.rawComponents;

  int get group => assignment.group;
}

/// The engine input for a contest, built from the stored official scores,
/// with what the results need to flag themselves preliminary.
///
/// Only flights credited to the round they were scheduled in are counted;
/// a make-up flight credited to another round waits for its own handling.
class F5jResultsInput {
  F5jResultsInput._({
    required this.input,
    required this.scored,
    required this.completedRounds,
    required Set<int> incompleteRounds,
    required Set<(int, int)> incompleteGroups,
  }) : incompleteRounds = Set.unmodifiable(incompleteRounds),
       incompleteGroups = Set.unmodifiable(incompleteGroups);

  /// Reads the contest's current matrix and scores.
  ///
  /// With [includePreliminaryAttempts] a flight without an official score is
  /// counted from its newest submitted attempt and flagged preliminary
  /// ([ScoredSlot.isPreliminary]). Nothing built that way may be stored: it
  /// exists for the pilot's own views, while official results read official
  /// scores only.
  static Future<F5jResultsInput> build(
    Repository repository, {
    required Id contestId,
    required ContestConfigurationRevision revision,
    required List<Round> rounds,
    required List<ContestParticipation> participations,
    required bool teamsEnabled,
    bool includePreliminaryAttempts = false,
  }) async {
    final byId = {for (final p in participations) p.id: p};
    final placeholders = {
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        placeholder.assignmentId: placeholder,
    };

    // Every placeholder's current score, in one read.
    final officials = await repository.officialScoreRepository
        .currentForPlaceholders([
          for (final placeholder in placeholders.values) placeholder.id,
        ]);
    final landing = LandingBonusResolver(repository, revision);

    // Newest submitted attempt of each placeholder that has no official
    // score, in one read.
    var attempts = const <Id, ScoreAttempt>{};
    if (includePreliminaryAttempts) {
      attempts = await repository.scoreAttemptRepository.latestForPlaceholders([
        for (final placeholder in placeholders.values)
          if (placeholder.scoreRevision != 0) placeholder.id,
      ]);
    }
    Future<({OfficialScore? official, ScoreAttempt? attempt})?> scoreOf(
      ScorePlaceholder placeholder,
    ) async {
      final official = officials[placeholder.id];
      if (official != null) return (official: official, attempt: null);
      final attempt = attempts[placeholder.id];
      return attempt == null ? null : (official: null, attempt: attempt);
    }

    final scored = <ScoredSlot>[];
    final roundInputs = <F5jRoundInput>[];
    final incompleteRounds = <int>{};
    final incompleteGroups = <(int, int)>{};
    var completedRounds = 0;
    for (final round in rounds) {
      final groups = <int, List<F5jFlightEntry>>{};
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        round.id,
      );
      // A pilot whose re-flight is scored counts one flight for the round: the
      // latest scored re-flight (the highest flight sequence; a re-flight of a
      // re-flight takes the next number). The flights it replaced no longer
      // count. The documented rule is "the discipline's result-selection
      // rule"; for F5J this is the latest scored flight (see #752).
      final counted = <Id, MatrixAssignment>{};
      for (final assignment in live) {
        if (assignment.assignmentType != AssignmentType.reflight) continue;
        final placeholder = placeholders[assignment.id];
        if (placeholder == null || await scoreOf(placeholder) == null) {
          continue;
        }
        final best = counted[assignment.contestParticipationId];
        if (best == null || assignment.flightSequence > best.flightSequence) {
          counted[assignment.contestParticipationId] = assignment;
        }
      }
      for (final assignment in live) {
        final chosen = counted[assignment.contestParticipationId];
        if (chosen != null &&
            (assignment.assignmentType == AssignmentType.original ||
                assignment.assignmentType == AssignmentType.reflight) &&
            assignment.id != chosen.id) {
          continue;
        }
        if (assignment.creditedRoundId != assignment.scheduledRoundId) continue;
        final participation = byId[assignment.contestParticipationId];
        if (participation == null || !participation.isPilot) continue;
        final retired = participation.hasRetiredBy(round.ordinal);
        final placeholder = placeholders[assignment.id];
        final score = placeholder == null ? null : await scoreOf(placeholder);
        if (score == null) {
          if (!retired) {
            incompleteRounds.add(round.ordinal);
            incompleteGroups.add((round.ordinal, assignment.group));
          }
          continue;
        }
        scored.add(
          ScoredSlot(
            round: round,
            assignment: assignment,
            placeholder: placeholder!,
            officialScore: score.official,
            attempt: score.attempt,
          ),
        );
        final components = scored.last.components;
        groups
            .putIfAbsent(assignment.group, () => [])
            .add(
              F5jFlightEntry(
                pilotId: participation.id.value,
                components: components,
                landingBonus: await landing.bonusOf(components),
                retired: retired,
              ),
            );
      }
      if (groups.isEmpty) continue;
      completedRounds = round.ordinal;
      final numbers = groups.keys.toList()..sort();
      roundInputs.add(
        F5jRoundInput(
          round: round.ordinal,
          groups: [for (final number in numbers) groups[number]!],
        ),
      );
    }

    final pilots = participations.where((p) => p.isPilot).toList();
    final teams = <TeamEntry>[];
    if (teamsEnabled) {
      final members = <Id, List<String>>{};
      for (final membership
          in await repository.teamMembershipRepository.listForContest(
            contestId,
          )) {
        final pilot = byId[membership.contestParticipationId];
        if (pilot == null || !pilot.isPilot) continue;
        members.putIfAbsent(membership.teamId, () => []).add(pilot.id.value);
      }
      for (final entry in members.entries) {
        teams.add(TeamEntry(teamId: entry.key.value, pilotIds: entry.value));
      }
    }

    return F5jResultsInput._(
      input: F5jContestInput(
        pilotIds: [for (final p in pilots) p.id.value],
        rounds: roundInputs,
        retiredAtRound: {
          for (final p in pilots)
            if (p.retiredAtRound != null) p.id.value: p.retiredAtRound!,
        },
        teams: teams,
      ),
      scored: scored,
      completedRounds: completedRounds,
      incompleteRounds: incompleteRounds,
      incompleteGroups: incompleteGroups,
    );
  }

  final F5jContestInput input;

  /// Every flight that has an official score.
  final List<ScoredSlot> scored;

  /// The latest round with a score; the standings run up to it.
  final int completedRounds;

  /// Rounds (by ordinal) with a flight that is not scored yet.
  final Set<int> incompleteRounds;

  /// Groups, as (round ordinal, group number), with a flight not scored yet.
  final Set<(int, int)> incompleteGroups;

  /// Whether a standing as of [round] counts a round with missing scores.
  bool isIncompleteAsOf(int round) =>
      incompleteRounds.any((ordinal) => ordinal <= round);
}
