import 'package:json_annotation/json_annotation.dart';

/// The result of an audited action.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum AuditOutcome {
  @JsonValue('Success')
  success,
  @JsonValue('Rejected')
  rejected,
  @JsonValue('Conflict')
  conflict,
}
