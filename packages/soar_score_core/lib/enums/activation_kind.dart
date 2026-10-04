import 'package:json_annotation/json_annotation.dart';

/// Why an installation was given administrative authority over a contest.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum ActivationKind {
  @JsonValue('Initial')
  initial,
  @JsonValue('Replacement')
  replacement,
  @JsonValue('Reclaim')
  reclaim,
}
