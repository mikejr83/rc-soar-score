import 'package:json_annotation/json_annotation.dart';

/// Whether a round group is locked.
///
/// Serializes as the exact text in `plan/data-model/entities/round_group.md`.
enum GroupStatus {
  @JsonValue('Open')
  open,
  @JsonValue('Locked')
  locked,
}
