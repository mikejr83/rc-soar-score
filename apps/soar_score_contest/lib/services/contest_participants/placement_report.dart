import 'package:soar_score_core/soar_score_core.dart';

/// What happened when a pilot who joined after the draw was put in the
/// rounds, for the banner the page shows.
class PlacementReport {
  const PlacementReport({required this.name, required this.result});

  final String name;
  final LatePlacementResult result;

  /// The rounds already fully scored, where the pilot got a zero.
  List<int> get zeroedRounds => [for (final r in result.zeroed) r.round];

  /// The rounds no group could take the pilot in, with why.
  List<({int round, String reason})> get skipped => [
    for (final r in result.skipped)
      (round: r.round, reason: r.skippedReason ?? ''),
  ];

  bool get placedEverywhere => result.skipped.isEmpty;
}
