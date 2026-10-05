import 'dart:math';

import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

/// Randomised but repeatable checks that hold for every input.
void main() {
  final profile = F5jProfile();
  const runs = 2000;

  Map<String, Object?> randomComponents(Random r) {
    final c = <String, Object?>{};
    if (r.nextInt(10) > 0) c['time_flown'] = r.nextInt(1300) / 2;
    if (r.nextInt(10) > 0) c['launch_height'] = r.nextInt(500);
    if (r.nextInt(8) == 0) c['late_landing'] = r.nextBool();
    if (r.nextInt(12) == 0) c['motor_restart'] = r.nextBool();
    if (r.nextInt(12) == 0) c['out_of_bounds'] = r.nextBool();
    if (r.nextInt(12) == 0) c['no_altitude_recorded'] = r.nextBool();
    if (r.nextInt(6) == 0) c['flight_penalty'] = r.nextInt(300);
    return c;
  }

  group('flight invariants', () {
    test('are never negative, never NaN, and repeat exactly', () {
      final r = Random(42);
      var scored = 0;
      for (var i = 0; i < runs; i++) {
        final components = randomComponents(r);
        final before = Map.of(components);
        final bonus = r.nextInt(100).toDouble();
        F5jFlightResult result;
        try {
          result = profile.calculate(components, landingBonus: bonus);
        } on ScoringValidationError {
          expect(components, before, reason: 'input must not change');
          continue;
        }
        scored++;
        expect(result.rawScore.isFinite, isTrue, reason: '$components');
        expect(result.rawScore, greaterThanOrEqualTo(0), reason: '$components');
        if (result.zeroReasons.isNotEmpty) {
          expect(result.rawScore, 0, reason: '$components');
        }
        final again = profile.calculate(components, landingBonus: bonus);
        expect(again.rawScore, result.rawScore);
        expect(again.outcome, result.outcome);
        expect(components, before, reason: 'input must not change');
      }
      expect(scored, greaterThan(runs ~/ 4));
    });
  });

  group('group invariants', () {
    test('are finite, bounded, and normalise the best pilot to 1000', () {
      final r = Random(7);
      final options = profile.options().groupScore;
      for (var i = 0; i < 500; i++) {
        final pilots = <PilotRound>[];
        for (var p = 0; p < 1 + r.nextInt(10); p++) {
          try {
            pilots.add(
              profile
                  .calculate(randomComponents(r))
                  .toPilotRound('p$p', retired: r.nextInt(15) == 0),
            );
          } on ScoringValidationError {
            continue;
          }
        }
        if (pilots.isEmpty) continue;
        final entries = calculateGroupScores(pilots, options);
        expect(entries, hasLength(pilots.length));
        for (final e in entries) {
          expect(e.rawScore.isFinite && e.groupScore.isFinite, isTrue);
          expect(e.groupScore, inInclusiveRange(0, 1000));
        }
        final again = calculateGroupScores(pilots, options);
        expect(again, entries);
      }
    });
  });

  group('contest total invariants', () {
    test('drop only eligible rounds and keep penalties out of drops', () {
      final r = Random(99);
      for (var i = 0; i < 500; i++) {
        final roundCount = 1 + r.nextInt(10);
        final scores = [
          for (var n = 1; n <= roundCount; n++)
            if (r.nextInt(8) > 0)
              RoundScore(
                round: n,
                groupScore: r.nextInt(1001) / 1,
                rawScore: r.nextInt(1001) / 1,
                nonDroppable: r.nextInt(6) == 0,
                cumulativePenalty: r.nextInt(5) == 0 ? r.nextInt(100) / 1 : 0,
                underReview: r.nextInt(10) == 0,
              ),
        ];
        final pilot = PilotRounds(pilotId: 'p', scores: scores);
        final due = <List<int>>[
          [],
          [4],
          [4, 8],
        ][r.nextInt(3)];
        final options = ContestTotalOptions(dropAfterRounds: due);
        final asOf = 1 + r.nextInt(12);
        final total = calculateContestTotal(
          pilot,
          asOfRound: asOf,
          options: options,
        );

        final dueNow = due.where((d) => d <= asOf).length;
        expect(total.droppedRounds.length + total.skippedDrops, dueNow);
        for (final n in total.droppedRounds) {
          final s = scores.where((x) => x.round == n);
          if (s.isNotEmpty) expect(s.single.nonDroppable, isFalse);
        }
        final penalties = scores
            .where((s) => s.round <= asOf)
            .fold<double>(0, (a, s) => a + s.cumulativePenalty);
        expect(total.penaltyTotal, closeTo(penalties, 1e-9));
        expect(total.overallScore.isFinite, isTrue);
        expect(total.rawTotal, greaterThanOrEqualTo(0));

        final again = calculateContestTotal(
          pilot,
          asOfRound: asOf,
          options: options,
        );
        expect(again, total);
      }
    });
  });
}
