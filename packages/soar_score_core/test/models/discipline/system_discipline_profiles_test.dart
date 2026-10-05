import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../../support/discipline_documents.dart';

void main() {
  final profiles = {
    'f5j': SystemDisciplineProfiles.f5j,
    'f3j': SystemDisciplineProfiles.f3j,
    'ales': SystemDisciplineProfiles.ales,
    'thermal': SystemDisciplineProfiles.thermal,
  };
  final tableIds = {
    for (final table in SystemLandingTables.all) table.table.id,
  };

  group('SystemDisciplineProfiles', () {
    test('ships F5J, F3J, ALES and Thermal with the example ids', () {
      expect(SystemDisciplineProfiles.all.map((p) => p.profile.id.value), [
        '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01',
        '019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01',
        '019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01',
        '019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01',
      ]);
      expect(SystemDisciplineProfiles.all.map((p) => p.profile.type), [
        DisciplineType.f5j,
        DisciplineType.f3j,
        DisciplineType.ales,
        DisciplineType.thermalDuration,
      ]);
    });

    test('every profile is published at version 1', () {
      for (final shipped in SystemDisciplineProfiles.all) {
        expect(shipped.profile.status, ProfileStatus.published);
        expect(shipped.profile.version, 1);
        expect(shipped.profile.supersededBy, isNull);
      }
    });

    test('every profile names a shipped system landing table', () {
      for (final shipped in SystemDisciplineProfiles.all) {
        expect(
          tableIds,
          contains(shipped.profile.defaultLandingTableId),
          reason: shipped.profile.name,
        );
      }
    });

    test('every profile has exactly one primary formula', () {
      for (final shipped in SystemDisciplineProfiles.all) {
        expect(
          shipped.formulas.where((f) => f.isPrimary),
          hasLength(1),
          reason: shipped.profile.name,
        );
      }
    });

    test('child ids are unique across every shipped profile', () {
      final ids = [
        for (final shipped in SystemDisciplineProfiles.all) ...[
          shipped.profile.id,
          ...shipped.configFields.map((c) => c.id),
          ...shipped.scoreFields.map((c) => c.id),
          ...shipped.validations.map((c) => c.id),
          ...shipped.formulas.map((c) => c.id),
          ...shipped.rules.map((c) => c.id),
        ],
      ];

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the profile defaults only suggest core options', () {
      expect(SystemDisciplineProfiles.ales.profile.defaultOptions, {
        'group_score_mode': 'Time',
      });
      expect(SystemDisciplineProfiles.f3j.profile.defaultOptions, {
        'rounding_mode': 'Truncate',
      });
      expect(SystemDisciplineProfiles.f5j.profile.defaultOptions, isNull);
      expect(SystemDisciplineProfiles.thermal.profile.defaultOptions, isNull);
    });

    for (final MapEntry(key: name, value: shipped) in profiles.entries) {
      test('$name matches its example document', () {
        final document = disciplineDocument(name);
        List<T> rows<T>(
          String section,
          T Function(Map<String, Object?> json) fromJson,
        ) => [
          for (final row in document[section]! as List)
            fromJson(row as Map<String, Object?>),
        ];

        expect(
          shipped.profile,
          DisciplineProfile.fromJson(
            document['DisciplineProfile']! as Map<String, Object?>,
          ),
        );
        expect(
          shipped.configFields,
          rows('DisciplineConfigField', DisciplineConfigField.fromJson),
        );
        expect(
          shipped.scoreFields,
          rows('DisciplineScoreField', DisciplineScoreField.fromJson),
        );
        expect(
          shipped.validations,
          rows('DisciplineValidation', DisciplineValidation.fromJson),
        );
        expect(
          shipped.formulas,
          rows('DisciplineFormula', DisciplineFormula.fromJson),
        );
        expect(shipped.rules, rows('DisciplineRule', DisciplineRule.fromJson));
      });
    }
  });
}
