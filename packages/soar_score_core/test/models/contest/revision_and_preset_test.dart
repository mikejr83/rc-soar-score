import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

ContestConfigurationRevision makeRevision({int number = 2}) =>
    ContestConfigurationRevision(
      id: id(0x70),
      contestId: id(0x10),
      revisionNumber: number,
      disciplineProfileId: id(0x500),
      sourcePresetId: id(0x71),
      config: makeConfig(),
      landingTableId: id(0x501),
      createdBy: id(1),
      notes: 'Turned on team protection',
      createdAt: DateTime.utc(2026, 10, 10, 19, 30),
    );

ContestConfigurationPreset makePreset({String name = 'Club ALES'}) =>
    ContestConfigurationPreset(
      id: id(0x71),
      ownerAccountId: id(1),
      disciplineProfileId: id(0x500),
      name: name,
      config: makeConfig(),
      createdAt: DateTime.utc(2026, 8, 15, 17),
      updatedAt: DateTime.utc(2026, 9),
    );

void main() {
  group('ContestConfigurationRevision', () {
    test('round trips, keeping the config exactly', () {
      final revision = makeRevision();
      final json = revision.toJson();
      expect(json['config'], makeConfig().toJson());
      expect(json['revision_number'], 2);
      expect(ContestConfigurationRevision.fromJson(json), revision);
    });

    test('numbers start at 1', () {
      expect(makeRevision(number: 1).revisionNumber, 1);
      expect(() => makeRevision(number: 0), throwsArgumentError);
    });

    test('is append-only contest data with no row revision', () {
      final revision = makeRevision();
      expect(revision, isA<SyncScoped>());
      expect(revision, isNot(isA<Synchronizable>()));
      expect(revision.syncScope, SyncScope.contest);
    });
  });

  group('ContestConfigurationPreset', () {
    test('round trips with revision defaulting to 0', () {
      final preset = makePreset();
      expect(preset.revision, 0);
      expect(preset.toJson()['description'], isNull);
      expect(ContestConfigurationPreset.fromJson(preset.toJson()), preset);
    });

    test('is director data with an identity', () {
      final preset = makePreset();
      expect(preset, isA<Synchronizable>());
      expect(preset.syncScope, SyncScope.director);
      expect(preset.entityType, 'ContestConfigurationPreset');
    });

    test('trims the name and rejects a blank one', () {
      expect(makePreset(name: '  Club  ').name, 'Club');
      expect(() => makePreset(name: ' '), throwsArgumentError);
    });
  });
}
