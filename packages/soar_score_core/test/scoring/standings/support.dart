import 'package:soar_score_core/soar_score_core.dart';

/// A total as of round 4 with just the values ranking looks at.
ContestTotal pilotTotal(
  String id,
  double overall, {
  double dropped = 0,
  double rawPoints = 0,
  bool preliminary = false,
}) => ContestTotal(
  pilotId: id,
  asOfRound: 4,
  rawTotal: overall,
  droppedRounds: const [],
  skippedDrops: 0,
  droppedScoreTotal: dropped,
  rawFlightPoints: rawPoints,
  penaltyTotal: 0,
  overallScore: overall,
  isPreliminary: preliminary,
);

/// `id: [place, isTied]` for every pilot in the ranking.
Map<String, List<Object>> placesOf(PilotRanking ranking) => {
  for (final p in ranking.places) p.pilotId: [p.place, p.isTied],
};
