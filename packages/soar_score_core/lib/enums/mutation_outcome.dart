import 'package:json_annotation/json_annotation.dart';

/// The outcome of a client mutation.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum MutationOutcome {
  @JsonValue('Pending')
  pending,
  @JsonValue('Accepted')
  accepted,
  @JsonValue('Rejected')
  rejected,
  @JsonValue('Conflict')
  conflict,
  @JsonValue('Skipped')
  skipped,
}
