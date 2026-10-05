import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_issue.dart';
import '../totals/contest_total.dart';
import 'pilot_ranking.dart';
import 'team_entry.dart';
import 'team_place.dart';

/// Ranks teams by the sum of their best [pilotCount] pilot scores.
///
/// A team with fewer pilots counts them all, and a member with no total (a
/// non-flier) is skipped. Ties use the team fallback tie-breakers: the lowest
/// sum of the counted pilots' places, then the best individual place. Teams
/// still level share a place and are marked tied.
List<TeamPlace> rankTeams(
  List<TeamEntry> teams,
  List<ContestTotal> totals,
  PilotRanking ranking, {
  required int pilotCount,
}) {
  if (pilotCount < 1) throw ArgumentError.value(pilotCount, 'pilotCount');
  if (teams.map((t) => t.teamId).toSet().length != teams.length) {
    throw ScoringValidationError([
      const ScoringIssue(
        code: 'duplicate_team',
        message: 'A team appears twice.',
      ),
    ]);
  }
  final totalOf = {for (final t in totals) t.pilotId: t};

  final standings = <_Standing>[];
  for (final team in teams) {
    final members =
        [
          for (final id in team.pilotIds)
            if (totalOf[id] != null && ranking.placeOf(id) != null) id,
        ]..sort((a, b) {
          final byScore = totalOf[b]!.overallScore.compareTo(
            totalOf[a]!.overallScore,
          );
          return byScore != 0
              ? byScore
              : ranking.placeOf(a)!.place.compareTo(ranking.placeOf(b)!.place);
        });
    final counted = members.take(pilotCount).toList();
    final placeNumbers = [for (final id in counted) ranking.placeOf(id)!.place];
    standings.add(
      _Standing(
        team: team,
        counted: counted,
        total: counted.fold(
          0,
          (sum, id) => sum + (totalOf[id]!.overallScore * 1000).round(),
        ),
        placeSum: placeNumbers.isEmpty
            ? 1 << 30
            : placeNumbers.fold(0, (a, b) => a + b),
        bestPlace: placeNumbers.isEmpty
            ? 1 << 30
            : placeNumbers.reduce((a, b) => a < b ? a : b),
        preliminary: counted.any((id) => totalOf[id]!.isPreliminary),
      ),
    );
  }

  final places = [
    for (final s in standings)
      () {
        var ahead = 0;
        var level = 0;
        for (final other in standings) {
          if (identical(other, s)) continue;
          final c = other.compareTo(s);
          if (c > 0) ahead++;
          if (c == 0) level++;
        }
        return TeamPlace(
          teamId: s.team.teamId,
          place: ahead + 1,
          isTied: level > 0,
          total: s.total / 1000,
          countedPilotIds: s.counted,
          isPreliminary: s.preliminary,
        );
      }(),
  ];
  final position = {for (var i = 0; i < teams.length; i++) teams[i].teamId: i};
  places.sort((a, b) {
    final byPlace = a.place.compareTo(b.place);
    return byPlace != 0
        ? byPlace
        : position[a.teamId]!.compareTo(position[b.teamId]!);
  });
  return places;
}

class _Standing {
  _Standing({
    required this.team,
    required this.counted,
    required this.total,
    required this.placeSum,
    required this.bestPlace,
    required this.preliminary,
  });

  final TeamEntry team;
  final List<String> counted;

  /// Thousandths.
  final int total;
  final int placeSum;
  final int bestPlace;
  final bool preliminary;

  /// Positive when this team ranks ahead of [other].
  int compareTo(_Standing other) {
    final byTotal = total.compareTo(other.total);
    if (byTotal != 0) return byTotal;
    final byPlaceSum = other.placeSum.compareTo(placeSum); // lower is better
    if (byPlaceSum != 0) return byPlaceSum;
    return other.bestPlace.compareTo(bestPlace); // lower is better
  }
}
