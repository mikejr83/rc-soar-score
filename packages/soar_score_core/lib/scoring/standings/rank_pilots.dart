import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_issue.dart';
import '../totals/contest_total.dart';
import 'pilot_place.dart';
import 'pilot_ranking.dart';

/// Ranks pilots by overall score, highest first.
///
/// With [tieBreakerEnabled] (the director's option), equal scores are broken
/// by the higher dropped-round score, then by the higher total of discipline
/// raw scores. No discipline defines its own tie-breaker yet, so without the
/// option, and for pilots still level after it, the tie stays unresolved:
/// they share a place and are marked tied.
///
/// Pilots are compared on exact thousandths of the overall and dropped
/// scores, and on millionths of the raw score total.
PilotRanking rankPilots(
  List<ContestTotal> totals, {
  bool tieBreakerEnabled = false,
}) {
  final ids = totals.map((t) => t.pilotId).toSet();
  if (ids.length != totals.length) {
    throw ScoringValidationError([
      const ScoringIssue(
        code: 'duplicate_pilot',
        message: 'A pilot appears twice in the standings.',
      ),
    ]);
  }

  List<int> key(ContestTotal t) => [
    _scaled(t.overallScore, 1000),
    if (tieBreakerEnabled) _scaled(t.droppedScoreTotal, 1000),
    if (tieBreakerEnabled) _scaled(t.rawFlightPoints, 1000000),
  ];

  final keys = {for (final t in totals) t.pilotId: key(t)};
  final places = [
    for (final t in totals)
      () {
        final mine = keys[t.pilotId]!;
        var ahead = 0;
        var level = 0;
        for (final other in totals) {
          if (other.pilotId == t.pilotId) continue;
          final c = _compare(keys[other.pilotId]!, mine);
          if (c > 0) ahead++;
          if (c == 0) level++;
        }
        return PilotPlace(
          pilotId: t.pilotId,
          place: ahead + 1,
          isTied: level > 0,
        );
      }(),
  ];
  // Dart's sort is not stable, so order by place and then input position.
  final position = {
    for (var i = 0; i < totals.length; i++) totals[i].pilotId: i,
  };
  places.sort((a, b) {
    final byPlace = a.place.compareTo(b.place);
    return byPlace != 0
        ? byPlace
        : position[a.pilotId]!.compareTo(position[b.pilotId]!);
  });
  return PilotRanking(
    places: places,
    isPreliminary: totals.any((t) => t.isPreliminary),
  );
}

int _scaled(double value, int scale) => (value * scale).round();

/// Positive when [a] ranks ahead of [b] (a larger key wins).
int _compare(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    final c = a[i].compareTo(b[i]);
    if (c != 0) return c;
  }
  return 0;
}
