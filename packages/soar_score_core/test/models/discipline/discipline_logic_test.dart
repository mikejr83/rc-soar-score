import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

DisciplineValidation validation(List<String> keys) => DisciplineValidation(
  id: exampleId(1),
  disciplineProfileId: exampleId(2),
  fieldKeys: keys,
  constraintType: 'mutually_exclusive',
  createdAt: t0,
);

DisciplineFormula formula({
  List<String> dependsOn = const [],
  FormulaType type = FormulaType.finalFormula,
}) => DisciplineFormula(
  id: exampleId(3),
  disciplineProfileId: exampleId(2),
  formulaKey: 'final_score',
  formulaText: 'flight + landing',
  formulaType: type,
  inputs: const {'flight': 'float'},
  dependsOn: dependsOn,
  createdAt: t0,
);

DisciplineRule rule({
  RuleType type = RuleType.zero,
  String? displayName = 'Out of bounds',
  List<String> dependsOn = const [],
}) => DisciplineRule(
  id: exampleId(4),
  disciplineProfileId: exampleId(2),
  ruleKey: 'oob',
  ruleType: type,
  displayName: displayName,
  dependsOn: dependsOn,
  createdAt: t0,
);

void main() {
  group('DisciplineValidation', () {
    test('round trips and is system scoped', () {
      final v = validation(['a', 'b']);
      expect(DisciplineValidation.fromJson(v.toJson()), v);
      expect(v.syncScope, SyncScope.system);
    });

    test('needs at least two field keys', () {
      expect(() => validation(['a']), throwsArgumentError);
    });
  });

  group('DisciplineFormula', () {
    test('round trips with "final" as the type text', () {
      final f = formula();
      expect(f.toJson()['formula_type'], 'final');
      expect(DisciplineFormula.fromJson(f.toJson()), f);
      expect(f.syncScope, SyncScope.system);
    });

    test('cannot depend on itself', () {
      expect(() => formula(dependsOn: ['final_score']), throwsArgumentError);
      expect(formula(dependsOn: ['raw']).dependsOn, ['raw']);
    });
  });

  group('DisciplineRule', () {
    test('round trips', () {
      final r = rule();
      expect(r.toJson()['rule_type'], 'zero');
      expect(DisciplineRule.fromJson(r.toJson()), r);
      expect(r.syncScope, SyncScope.system);
      expect(r.autoScoreZero, isTrue);
    });

    test('a zero rule needs a display name', () {
      expect(() => rule(displayName: null), throwsArgumentError);
      expect(rule(type: RuleType.penalty, displayName: null).displayName, null);
    });

    test('cannot depend on itself', () {
      expect(() => rule(dependsOn: ['oob']), throwsArgumentError);
    });
  });
}
