import 'dart:math';

import '../../enums/discipline_type.dart';
import '../../enums/score_field_type.dart';
import '../../errors/scoring_validation_error.dart';
import 'scoring_field_definition.dart';
import 'scoring_issue.dart';

/// An official, versioned scoring profile for one discipline.
///
/// Field ids and meanings never change within a [rulesVersion]; a changed rule
/// needs a new version so historical scores are not reinterpreted.
abstract class ScoringProfile {
  const ScoringProfile();

  DisciplineType get discipline;
  int get rulesVersion;

  /// Machine-readable definitions of every input, status and derived field.
  List<ScoringFieldDefinition> get fields;

  /// Default contest options when this discipline is selected. Contest
  /// overrides are stored as data and laid over these.
  Map<String, Object?> get defaultOptions;

  /// Checks rules that span several fields, after each field passed its own
  /// checks. The default has none.
  List<ScoringIssue> validateCombination(Map<String, Object?> components) =>
      const [];

  ScoringFieldDefinition? field(String id) {
    for (final f in fields) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Returns every problem with [components]; empty means valid.
  List<ScoringIssue> validate(Map<String, Object?> components) {
    final issues = <ScoringIssue>[];
    for (final key in components.keys) {
      final definition = field(key);
      if (definition == null) {
        issues.add(
          ScoringIssue(
            code: 'unknown_field',
            fieldId: key,
            message: 'Unknown field "$key".',
          ),
        );
      } else if (!definition.acceptedInSubmission) {
        issues.add(
          ScoringIssue(
            code: 'derived_field',
            fieldId: key,
            message: '"$key" is derived and cannot be submitted.',
          ),
        );
      }
    }
    for (final definition in fields.where((f) => f.acceptedInSubmission)) {
      final value = components[definition.id];
      if (value == null) {
        if (definition.required) {
          issues.add(
            ScoringIssue(
              code: 'required',
              fieldId: definition.id,
              message: '"${definition.id}" is required.',
            ),
          );
        }
        continue;
      }
      issues.addAll(_validateValue(definition, value));
    }
    if (issues.isEmpty) issues.addAll(validateCombination(components));
    return issues;
  }

  /// Throws [ScoringValidationError] when [components] are invalid.
  void validateOrThrow(Map<String, Object?> components) {
    final issues = validate(components);
    if (issues.isNotEmpty) throw ScoringValidationError(issues);
  }

  /// Contest options: profile defaults with [overrides] laid over them.
  ///
  /// An override of an option the profile does not define is rejected.
  Map<String, Object?> resolveOptions([Map<String, Object?>? overrides]) {
    final unknown = (overrides?.keys ?? const <String>[]).where(
      (k) => !defaultOptions.containsKey(k),
    );
    if (unknown.isNotEmpty) {
      throw ScoringValidationError([
        for (final key in unknown)
          ScoringIssue(
            code: 'unknown_option',
            fieldId: key,
            message: 'Unknown option "$key".',
          ),
      ]);
    }
    return Map.unmodifiable({...defaultOptions, ...?overrides});
  }

  static List<ScoringIssue> _validateValue(
    ScoringFieldDefinition definition,
    Object value,
  ) {
    final id = definition.id;
    ScoringIssue issue(String code, String message) =>
        ScoringIssue(code: code, fieldId: id, message: message);

    switch (definition.type) {
      case ScoreFieldType.int:
        if (value is! int) return [issue('wrong_type', '"$id" must be whole.')];
      case ScoreFieldType.float || ScoreFieldType.time:
        if (value is! num || !value.isFinite) {
          return [issue('wrong_type', '"$id" must be a number.')];
        }
      case ScoreFieldType.bool:
        if (value is! bool) {
          return [issue('wrong_type', '"$id" must be true or false.')];
        }
      case ScoreFieldType.string ||
          ScoreFieldType.landing ||
          ScoreFieldType.date:
        if (value is! String) {
          return [issue('wrong_type', '"$id" must be text.')];
        }
      case ScoreFieldType.enumeration:
        if (!(definition.allowedValues ?? const []).contains(value)) {
          return [
            issue('not_allowed', '"$id" has a value that is not allowed.'),
          ];
        }
    }
    if (value is! num) return const [];
    final issues = <ScoringIssue>[];
    if (definition.min != null && value < definition.min!) {
      issues.add(
        issue('out_of_range', '"$id" must be at least ${definition.min}.'),
      );
    }
    if (definition.max != null && value > definition.max!) {
      issues.add(
        issue('out_of_range', '"$id" must be at most ${definition.max}.'),
      );
    }
    final precision = definition.precision;
    if (precision != null && value is! int) {
      final scaled = value * pow(10, precision);
      if ((scaled - scaled.roundToDouble()).abs() > 1e-9) {
        issues.add(
          issue(
            'too_precise',
            '"$id" allows at most $precision decimal places.',
          ),
        );
      }
    }
    return issues;
  }
}
