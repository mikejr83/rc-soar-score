import 'package:json_annotation/json_annotation.dart';

/// What a discipline rule does.
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_rule.md`.
enum RuleType {
  @JsonValue('calc')
  calc,
  @JsonValue('penalty')
  penalty,
  @JsonValue('zero')
  zero,
  @JsonValue('interaction')
  interaction,
  @JsonValue('other')
  other,
}
