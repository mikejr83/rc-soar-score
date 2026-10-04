import 'package:json_annotation/json_annotation.dart';

/// Whether a score field is entered, a status flag, or derived.
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_scorefield.md`.
enum ScoreFieldKind {
  @JsonValue('input')
  input,
  @JsonValue('status_flag')
  statusFlag,
  @JsonValue('derived')
  derived,
}
