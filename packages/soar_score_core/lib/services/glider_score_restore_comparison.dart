import '../models/imports/contest_import_plan.dart';
import '../models/imports/restore_plan.dart';
import '../scoring/f5j/f5j_profile.dart';

/// The outcome of recalculating every restored flight.
class RestoreComparisonResult {
  const RestoreComparisonResult({
    required this.checked,
    required this.mismatchCount,
    required this.mismatches,
  });

  /// Flights compared with GliderScore's `RawScore`.
  final int checked;

  /// How many flights differ.
  final int mismatchCount;

  /// The first few that differ.
  final List<RestoreMismatch> mismatches;

  bool get passed => mismatchCount == 0;
}

/// The gate of a restore: Soar Score's calculator against GliderScore's
/// `RawScore`, flight by flight (ADR 0006, amendment 2).
///
/// Pure. A flight the calculator refuses counts as a difference.
class GliderScoreRestoreComparison {
  const GliderScoreRestoreComparison();

  /// GliderScore stores the score as a number with a few decimals; two scores
  /// are the same when they agree to this much.
  static const tolerance = 1e-6;

  /// How many differing flights the result lists.
  static const listed = 5;

  /// Recalculates [flights]. [overrides] are the contest's discipline
  /// options; [landingPoints] gives the points of each landing entry key of
  /// the pinned landing table.
  RestoreComparisonResult check(
    List<RestoredFlight> flights, {
    required Map<String, Object?> overrides,
    required Map<String, double> landingPoints,
  }) {
    final profile = F5jProfile();
    var checked = 0;
    var count = 0;
    final listedMismatches = <RestoreMismatch>[];
    for (final flight in flights) {
      final expected = flight.sourceRawScore;
      if (expected == null) continue;
      checked++;
      double? actual;
      String? error;
      try {
        final entry = flight.components['landing'];
        final bonus = entry == null ? 0.0 : landingPoints['$entry'];
        if (bonus == null) {
          error = 'landing "$entry" is not in the landing table';
        } else {
          actual = profile
              .calculate(
                flight.components,
                overrides: overrides,
                landingBonus: bonus,
              )
              .rawScore;
        }
      } on Object catch (e) {
        error = '$e';
      }
      final same =
          error == null && (actual! - expected.toDouble()).abs() <= tolerance;
      if (same) continue;
      count++;
      if (listedMismatches.length < listed) {
        listedMismatches.add(
          RestoreMismatch(
            roundNo: flight.roundNo,
            groupNo: flight.sourceGroupNo,
            sourcePilotNo: flight.sourcePilotNo,
            reflightNo: flight.reflightNo,
            expected: expected,
            actual: actual,
            error: error,
          ),
        );
      }
    }
    return RestoreComparisonResult(
      checked: checked,
      mismatchCount: count,
      mismatches: listedMismatches,
    );
  }
}
