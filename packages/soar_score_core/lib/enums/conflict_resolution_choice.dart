import 'package:json_annotation/json_annotation.dart';

/// Which version a resolved conflict kept.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum ConflictResolutionChoice {
  @JsonValue('KeptAccepted')
  keptAccepted,
  @JsonValue('TookCompeting')
  tookCompeting,
  @JsonValue('Merged')
  merged,
}
