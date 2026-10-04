import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

LandingTable table({Id? owner}) => LandingTable(
  id: exampleId(1),
  ownerAccountId: owner,
  name: 'ALES landing',
  inputUnit: LandingInputUnit.meters,
  createdAt: t0,
);

LandingResult result({int points = 40, int ordinal = 3}) => LandingResult(
  id: exampleId(2),
  landingTableId: exampleId(1),
  entryKey: 'within_3m',
  displayValue: 'Within 3 m',
  pointValue: points,
  ordinalPosition: ordinal,
);

void main() {
  group('LandingTable', () {
    test('round trips', () {
      final t = table();
      expect(t.toJson()['input_unit'], 'meters');
      expect(LandingTable.fromJson(t.toJson()), t);
    });

    test('is system data without an owner, director data with one', () {
      expect(table().syncScope, SyncScope.system);
      expect(table(owner: exampleId(9)).syncScope, SyncScope.director);
    });

    test('input units use their documented text', () {
      for (final unit in ['meters', 'feet', 'points']) {
        final json = table().toJson()..['input_unit'] = unit;
        expect(LandingTable.fromJson(json).toJson()['input_unit'], unit);
      }
    });
  });

  group('LandingResult', () {
    test('round trips', () {
      final r = result();
      expect(LandingResult.fromJson(r.toJson()), r);
    });

    test('points and position cannot be negative', () {
      expect(() => result(points: -1), throwsArgumentError);
      expect(() => result(ordinal: -1), throwsArgumentError);
    });
  });
}
