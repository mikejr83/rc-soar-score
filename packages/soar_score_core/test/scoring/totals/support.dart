import 'package:soar_score_core/soar_score_core.dart';

/// A pilot with one score per entry; the round is the position, from 1.
PilotRounds pilot(
  List<double> scores, {
  Set<int> nonDroppable = const {},
  Map<int, double> penalties = const {},
  Set<int> underReview = const {},
  int? retiredAtRound,
}) => PilotRounds(
  pilotId: 'a',
  retiredAtRound: retiredAtRound,
  scores: [
    for (var i = 0; i < scores.length; i++)
      RoundScore(
        round: i + 1,
        groupScore: scores[i],
        rawScore: scores[i],
        nonDroppable: nonDroppable.contains(i + 1),
        cumulativePenalty: penalties[i + 1] ?? 0,
        underReview: underReview.contains(i + 1),
      ),
  ],
);

ContestTotal total(
  PilotRounds p, {
  required int asOf,
  List<int> dropAfter = const [],
}) => calculateContestTotal(
  p,
  asOfRound: asOf,
  options: ContestTotalOptions(dropAfterRounds: dropAfter),
);
