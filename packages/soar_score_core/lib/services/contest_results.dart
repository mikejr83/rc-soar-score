import 'package:equatable/equatable.dart';

import '../models/results/participation_standing.dart';
import '../models/results/team_standing.dart';

/// The standings of a contest as of its latest scored round.
///
/// [isPreliminary] is true while scores are missing or [isStale]. A result is
/// stale when it was computed under another configuration, matrix or
/// calculation version than the contest has now, or before the latest
/// official score; it must not be presented as official until recalculated.
class ContestResults extends Equatable {
  ContestResults({
    this.asOfRound,
    this.isStale = false,
    Iterable<ParticipationStanding> standings = const [],
    Iterable<TeamStanding> teams = const [],
  }) : standings = List.unmodifiable(standings),
       teams = List.unmodifiable(teams);

  factory ContestResults.fromJson(Map<String, Object?> json) => ContestResults(
    asOfRound: json['as_of_round'] as int?,
    isStale: json['stale']! as bool,
    standings: [
      for (final item in json['standings']! as List<Object?>)
        ParticipationStanding.fromJson(item! as Map<String, Object?>),
    ],
    teams: [
      for (final item in json['teams']! as List<Object?>)
        TeamStanding.fromJson(item! as Map<String, Object?>),
    ],
  );

  /// The latest round the standings count, null before any score.
  final int? asOfRound;
  final bool isStale;

  /// Pilot standings, best place first.
  final List<ParticipationStanding> standings;

  /// Team standings, best place first; empty when teams are off.
  final List<TeamStanding> teams;

  bool get isPreliminary =>
      isStale ||
      standings.any((s) => s.isPreliminary) ||
      teams.any((t) => t.isPreliminary);

  Map<String, Object?> toJson() => {
    'as_of_round': asOfRound,
    'stale': isStale,
    'preliminary': isPreliminary,
    'standings': [for (final item in standings) item.toJson()],
    'teams': [for (final item in teams) item.toJson()],
  };

  @override
  List<Object?> get props => [asOfRound, isStale, standings, teams];
}
