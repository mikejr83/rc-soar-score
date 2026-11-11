import 'package:equatable/equatable.dart';

import '../models/contest/contest.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/matrix/current_matrix.dart';
import '../models/participants/contest_participation.dart';
import '../models/participants/participant_profile.dart';
import '../models/teams/team.dart';
import '../models/teams/team_membership.dart';
import 'contest_results.dart';
import 'contest_scores.dart';
import 'round_results.dart';

/// What a report reads about one contest, answered by
/// `GET /contests/{id}/report-data` in a single response.
///
/// Which parts are present depends on what was asked for ([ReportInclude]):
/// the facts every report needs (contest, configuration, participations,
/// the contest's own participant profiles, teams, memberships, matrix and
/// official scores), and the stored standings and per-round flight results
/// the Overall Standings report adds. Official scores and results only; a
/// pilot's preliminary submissions are not part of it.
class ReportData extends Equatable {
  ReportData({
    required this.contest,
    this.configuration,
    this.participations,
    this.participants,
    this.teams,
    this.teamMemberships,
    this.matrix,
    this.scores,
    this.results,
    this.roundResults,
  });

  factory ReportData.fromJson(Map<String, Object?> json) {
    List<T>? list<T>(String key, T Function(Map<String, Object?>) read) {
      final items = json[key] as List<Object?>?;
      return items == null
          ? null
          : [for (final item in items) read(item! as Map<String, Object?>)];
    }

    Map<String, Object?>? object(String key) =>
        json[key] as Map<String, Object?>?;

    final configuration = object('configuration');
    final matrix = object('matrix');
    final scores = object('scores');
    final results = object('results');
    return ReportData(
      contest: Contest.fromJson(object('contest')!),
      configuration: configuration == null
          ? null
          : ContestConfigurationRevision.fromJson(configuration),
      participations: list('participations', ContestParticipation.fromJson),
      participants: list('participants', ParticipantProfile.fromJson),
      teams: list('teams', Team.fromJson),
      teamMemberships: list('team_memberships', TeamMembership.fromJson),
      matrix: matrix == null ? null : CurrentMatrix.fromJson(matrix),
      scores: scores == null ? null : ContestScores.fromJson(scores),
      results: results == null ? null : ContestResults.fromJson(results),
      roundResults: list('round_results', RoundResults.fromJson),
    );
  }

  final Contest contest;

  /// The latest saved configuration; `null` when none is saved yet, and also
  /// when the facts were not asked for.
  final ContestConfigurationRevision? configuration;

  /// `null` when the facts were not asked for.
  final List<ContestParticipation>? participations;

  /// Only the profiles of this contest's participations.
  final List<ParticipantProfile>? participants;
  final List<Team>? teams;
  final List<TeamMembership>? teamMemberships;
  final CurrentMatrix? matrix;

  /// The official scores; present when the facts or the scores were asked
  /// for.
  final ContestScores? scores;

  /// The stored standings as of the asked round; `null` when standings were
  /// not asked for or none is stored as of that round.
  final ContestResults? results;

  /// The flight results of each asked round, in the order asked.
  final List<RoundResults>? roundResults;

  Map<String, Object?> toJson() => {
    'contest': contest.toJson(),
    'configuration': configuration?.toJson(),
    'participations': participations == null
        ? null
        : [for (final item in participations!) item.toJson()],
    'participants': participants == null
        ? null
        : [for (final item in participants!) item.toJson()],
    'teams': teams == null ? null : [for (final t in teams!) t.toJson()],
    'team_memberships': teamMemberships == null
        ? null
        : [for (final item in teamMemberships!) item.toJson()],
    'matrix': matrix?.toJson(),
    'scores': scores?.toJson(),
    'results': results?.toJson(),
    'round_results': roundResults == null
        ? null
        : [for (final item in roundResults!) item.toJson()],
  };

  @override
  List<Object?> get props => [
    contest,
    configuration,
    participations,
    participants,
    teams,
    teamMemberships,
    matrix,
    scores,
    results,
    roundResults,
  ];
}
