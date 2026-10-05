import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

void main() {
  final shipped = SystemDisciplineProfiles.f3j;
  final other = SystemDisciplineProfiles.ales;

  DisciplineProfileWithRules rebuild({
    Iterable<DisciplineConfigField>? configFields,
    Iterable<DisciplineScoreField>? scoreFields,
    Iterable<DisciplineRule>? rules,
  }) => DisciplineProfileWithRules(
    profile: shipped.profile,
    configFields: configFields ?? shipped.configFields,
    scoreFields: scoreFields ?? shipped.scoreFields,
    validations: shipped.validations,
    formulas: shipped.formulas,
    rules: rules ?? shipped.rules,
  );

  group('DisciplineProfileWithRules', () {
    test('holds each list in display order', () {
      final shuffled = rebuild(configFields: shipped.configFields.reversed);

      expect(shuffled, shipped);
      expect(shuffled.configFields.map((f) => f.displayOrder), [1, 2, 3, 4]);
    });

    test('rejects a child of another profile', () {
      expect(
        () => rebuild(rules: [...shipped.rules, other.rules.first]),
        throwsArgumentError,
      );
    });

    test('rejects a repeated child id', () {
      expect(
        () => rebuild(
          configFields: [...shipped.configFields, shipped.configFields.first],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a repeated key within a list', () {
      final first = shipped.scoreFields.first;
      final copy = DisciplineScoreField(
        id: exampleId(77),
        disciplineProfileId: shipped.profile.id,
        fieldKey: first.fieldKey,
        fieldType: first.fieldType,
        name: 'Copy',
        createdAt: t0,
      );

      expect(
        () => rebuild(scoreFields: [...shipped.scoreFields, copy]),
        throwsArgumentError,
      );
    });
  });
}
