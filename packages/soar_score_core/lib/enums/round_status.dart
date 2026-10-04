import 'package:json_annotation/json_annotation.dart';

/// Whether a round accepts scores.
///
/// Serializes as the exact text in `plan/data-model/entities/round.md`.
enum RoundStatus {
  @JsonValue('Open')
  open,
  @JsonValue('Locked')
  locked,
  @JsonValue('Cancelled')
  cancelled,
}
