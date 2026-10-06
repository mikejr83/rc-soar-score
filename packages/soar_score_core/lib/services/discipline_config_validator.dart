import 'dart:convert';

import '../enums/config_field_type.dart';
import '../errors/scoring_validation_error.dart';
import '../models/discipline/discipline_config_field.dart';
import '../models/discipline/discipline_profile_with_rules.dart';
import '../scoring/profile/scoring_issue.dart';

/// Checks the `discipline` part of a contest configuration against the
/// configuration fields of its discipline profile.
///
/// Invalid input is rejected, never repaired: every problem is reported, and
/// nothing is filled in. A field that is left out reads as its default.
abstract final class DisciplineConfigValidator {
  /// Throws a [ScoringValidationError] listing every problem with
  /// [discipline] for [profile].
  static void validate(
    DisciplineProfileWithRules profile,
    Map<String, Object?> discipline,
  ) {
    final issues = <ScoringIssue>[];
    final fields = {for (final f in profile.configFields) f.fieldKey: f};

    for (final key in discipline.keys) {
      if (!fields.containsKey(key)) {
        issues.add(
          ScoringIssue(
            code: 'unknown_field',
            message: '"$key" is not a setting of ${profile.profile.name}.',
            fieldId: key,
          ),
        );
      }
    }

    for (final field in fields.values) {
      final key = field.fieldKey;
      if (field.fieldType == ConfigFieldType.landing) {
        // The landing table is chosen with the revision's landing_table_id,
        // never in the settings.
        if (discipline.containsKey(key)) {
          issues.add(
            ScoringIssue(
              code: 'landing_in_settings',
              message: '"$key" is set with landing_table_id, not here.',
              fieldId: key,
            ),
          );
        }
        continue;
      }
      final value = discipline[key];
      if (value == null) {
        if (field.required && field.defaultValue == null) {
          issues.add(
            ScoringIssue(
              code: 'required',
              message: '"${field.name}" is required.',
              fieldId: key,
            ),
          );
        }
        continue;
      }
      final issue = _check(field, value);
      if (issue != null) issues.add(issue);
    }

    if (issues.isNotEmpty) throw ScoringValidationError(issues);
  }

  static ScoringIssue? _check(DisciplineConfigField field, Object value) {
    final key = field.fieldKey;
    ScoringIssue wrongType(String expected) => ScoringIssue(
      code: 'wrong_type',
      message: '"${field.name}" must be $expected.',
      fieldId: key,
    );

    switch (field.fieldType) {
      case ConfigFieldType.int:
        if (value is! int) return wrongType('a whole number');
        return _checkRange(field, value);
      case ConfigFieldType.float:
        if (value is! num) return wrongType('a number');
        return _checkRange(field, value);
      case ConfigFieldType.bool:
        return value is bool ? null : wrongType('true or false');
      case ConfigFieldType.string:
        if (value is! String) return wrongType('text');
        final pattern = field.validation?['pattern'];
        if (pattern is String && !RegExp(pattern).hasMatch(value)) {
          return ScoringIssue(
            code: 'out_of_range',
            message: '"${field.name}" does not match the required format.',
            fieldId: key,
          );
        }
        return null;
      case ConfigFieldType.enumeration:
        final allowed = [
          for (final option in field.options ?? const <Object?>[])
            option is Map ? option['value'] : option,
        ];
        if (allowed.any((a) => jsonEncode(a) == jsonEncode(value))) {
          return null;
        }
        return ScoringIssue(
          code: 'not_allowed',
          message: '"${field.name}" must be one of ${allowed.join(', ')}.',
          fieldId: key,
        );
      case ConfigFieldType.landing:
        return null;
    }
  }

  static ScoringIssue? _checkRange(DisciplineConfigField field, num value) {
    final rules = field.validation;
    if (rules == null) return null;
    final unit = field.unit == null ? '' : ' ${field.unit}';
    ScoringIssue outOfRange(String bound) => ScoringIssue(
      code: 'out_of_range',
      message: '"${field.name}" must be $bound$unit.',
      fieldId: field.fieldKey,
    );

    final gt = rules['gt'];
    if (gt is num && !(value > gt)) return outOfRange('greater than $gt');
    final gte = rules['gte'] ?? rules['min'];
    if (gte is num && !(value >= gte)) return outOfRange('at least $gte');
    final lt = rules['lt'];
    if (lt is num && !(value < lt)) return outOfRange('less than $lt');
    final lte = rules['lte'] ?? rules['max'];
    if (lte is num && !(value <= lte)) return outOfRange('at most $lte');
    return null;
  }
}
