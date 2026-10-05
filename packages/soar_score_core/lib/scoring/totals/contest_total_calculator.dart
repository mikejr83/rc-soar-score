import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_issue.dart';
import 'contest_total.dart';
import 'contest_total_options.dart';
import 'pilot_rounds.dart';

/// Computes a pilot's contest total as of a completed round.
///
/// 1. Every round up to [asOfRound] counts. A round with no score is a zero;
///    after the pilot's retirement round it is a zero without a record, and
///    otherwise it makes the total preliminary.
/// 2. For each `drop_after_rounds` entry at or below [asOfRound], the lowest
///    eligible round is dropped. A non-droppable zero is never eligible. With
///    equal scores the earliest round is dropped. When no eligible round is
///    left, that drop is skipped and all remaining scores are kept.
/// 3. Cumulative penalties on every round are summed and subtracted after the
///    drops, so a dropped round never drops its penalty.
///
/// Scores are summed in thousandths, so the totals carry no floating-point
/// drift. A score with finer than three decimals is rejected.
ContestTotal calculateContestTotal(
  PilotRounds pilot, {
  required int asOfRound,
  required ContestTotalOptions options,
}) {
  if (asOfRound < 0) throw ArgumentError.value(asOfRound, 'asOfRound');

  final byRound = {
    for (final s in pilot.scores)
      if (s.round <= asOfRound) s.round: s,
  };
  final retiredAt = pilot.retiredAtRound;

  final scores = <int, int>{}; // round -> thousandths
  final nonDroppable = <int>{};
  var penalty = 0;
  var preliminary = false;
  for (var round = 1; round <= asOfRound; round++) {
    final entry = byRound[round];
    if (entry == null) {
      scores[round] = 0;
      if (retiredAt == null || round < retiredAt) preliminary = true;
      continue;
    }
    scores[round] = _thousandths(entry.groupScore, 'groupScore', round);
    penalty += _thousandths(
      entry.cumulativePenalty,
      'cumulativePenalty',
      round,
    );
    if (entry.nonDroppable) nonDroppable.add(round);
    if (entry.underReview) preliminary = true;
  }

  final drops = options.dropAfterRounds.where((t) => t <= asOfRound).length;
  final dropped = <int>[];
  var skipped = 0;
  for (var i = 0; i < drops; i++) {
    int? pick;
    for (final round in scores.keys) {
      if (nonDroppable.contains(round) || dropped.contains(round)) continue;
      if (pick == null || scores[round]! < scores[pick]!) pick = round;
    }
    if (pick == null) {
      skipped++;
    } else {
      dropped.add(pick);
    }
  }
  dropped.sort();

  final raw = scores.values.fold(0, (a, b) => a + b);
  final droppedSum = dropped.fold(0, (a, r) => a + scores[r]!);
  return ContestTotal(
    pilotId: pilot.pilotId,
    asOfRound: asOfRound,
    rawTotal: raw / 1000,
    droppedRounds: dropped,
    skippedDrops: skipped,
    penaltyTotal: penalty / 1000,
    overallScore: (raw - droppedSum - penalty) / 1000,
    isPreliminary: preliminary,
  );
}

int _thousandths(double value, String field, int round) {
  final scaled = value * 1000;
  if ((scaled - scaled.roundToDouble()).abs() > 1e-6) {
    throw ScoringValidationError([
      ScoringIssue(
        code: 'too_precise',
        fieldId: field,
        message: 'Round $round $field allows at most 3 decimal places.',
      ),
    ]);
  }
  return scaled.round();
}
