import 'package:equatable/equatable.dart';

import 'discipline_config_field.dart';
import 'discipline_formula.dart';
import 'discipline_profile.dart';
import 'discipline_rule.dart';
import 'discipline_score_field.dart';
import 'discipline_validation.dart';

/// A [DisciplineProfile] together with the child rows that define it, the
/// unit in which a profile is installed: all of it exists or none of it does.
///
/// Each list is held in display order. Construction rejects a child that
/// belongs to another profile, a repeated child id, and a repeated key within
/// a list.
class DisciplineProfileWithRules extends Equatable {
  DisciplineProfileWithRules({
    required this.profile,
    required Iterable<DisciplineConfigField> configFields,
    required Iterable<DisciplineScoreField> scoreFields,
    required Iterable<DisciplineValidation> validations,
    required Iterable<DisciplineFormula> formulas,
    required Iterable<DisciplineRule> rules,
  }) : configFields = _ordered(configFields, (f) => f.displayOrder),
       scoreFields = _ordered(scoreFields, (f) => f.displayOrder),
       validations = _ordered(validations, (v) => v.displayOrder),
       formulas = _ordered(formulas, (f) => f.displayOrder),
       rules = _ordered(rules, (r) => r.displayOrder) {
    final ids = <String>{profile.id.value};
    void check<T>(
      List<T> children,
      String list,
      String Function(T child) id,
      String Function(T child) profileOf,
      String Function(T child) key,
    ) {
      final keys = <String>{};
      for (final child in children) {
        if (profileOf(child) != profile.id.value) {
          throw ArgumentError.value(
            id(child),
            list,
            'belongs to another discipline profile',
          );
        }
        if (!ids.add(id(child))) {
          throw ArgumentError.value(id(child), list, 'id is repeated');
        }
        if (!keys.add(key(child))) {
          throw ArgumentError.value(key(child), list, 'key is repeated');
        }
      }
    }

    check<DisciplineConfigField>(
      this.configFields,
      'configFields',
      (c) => c.id.value,
      (c) => c.disciplineProfileId.value,
      (c) => c.fieldKey,
    );
    check<DisciplineScoreField>(
      this.scoreFields,
      'scoreFields',
      (c) => c.id.value,
      (c) => c.disciplineProfileId.value,
      (c) => c.fieldKey,
    );
    check<DisciplineValidation>(
      this.validations,
      'validations',
      (c) => c.id.value,
      (c) => c.disciplineProfileId.value,
      (c) => c.id.value,
    );
    check<DisciplineFormula>(
      this.formulas,
      'formulas',
      (c) => c.id.value,
      (c) => c.disciplineProfileId.value,
      (c) => c.formulaKey,
    );
    check<DisciplineRule>(
      this.rules,
      'rules',
      (c) => c.id.value,
      (c) => c.disciplineProfileId.value,
      (c) => c.ruleKey,
    );
  }

  final DisciplineProfile profile;

  /// The options a director can change for a contest, by display order.
  final List<DisciplineConfigField> configFields;

  /// The values entered or derived for each score, by display order.
  final List<DisciplineScoreField> scoreFields;

  final List<DisciplineValidation> validations;
  final List<DisciplineFormula> formulas;
  final List<DisciplineRule> rules;

  static List<T> _ordered<T>(Iterable<T> rows, int Function(T row) order) {
    final sorted = [...rows];
    // Dart's sort is not stable, so break ties by the original position.
    final position = {for (final (i, row) in sorted.indexed) row: i};
    sorted.sort((a, b) {
      final byOrder = order(a) - order(b);
      return byOrder != 0 ? byOrder : position[a]! - position[b]!;
    });
    return List.unmodifiable(sorted);
  }

  @override
  List<Object?> get props => [
    profile,
    configFields,
    scoreFields,
    validations,
    formulas,
    rules,
  ];
}
