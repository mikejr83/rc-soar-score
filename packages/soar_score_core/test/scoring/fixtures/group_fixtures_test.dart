import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixture_files.dart';

void main() {
  final profile = F5jProfile();

  for (final fixture in loadF5jFixtures('groups.json')) {
    test(fixture['name'] as String, () {
      final options = asMap(fixture['options']);
      final pilots = [
        for (final p in asMaps(fixture['pilots']))
          profile
              .calculate(
                asMap(p['components']),
                overrides: options,
                landingBonus: asDouble(p['landing_bonus'] ?? 0),
              )
              .toPilotRound(p['id'] as String, retired: p['retired'] == true),
      ];

      final entries = calculateGroupScores(
        pilots,
        profile.options(options).groupScore,
      );

      final expected = asMaps(fixture['expected']);
      expect(entries.map((e) => e.pilotId), [
        for (final e in expected) e['id'],
      ]);
      for (var i = 0; i < expected.length; i++) {
        final id = expected[i]['id'];
        expect(
          entries[i].rawScore,
          closeTo(asDouble(expected[i]['raw_score']), 1e-9),
          reason: '$id raw score',
        );
        expect(
          entries[i].groupScore,
          closeTo(asDouble(expected[i]['group_score']), 1e-9),
          reason: '$id group score',
        );
      }
    });
  }
}
