import 'package:json_annotation/json_annotation.dart';

/// Whether the server has acknowledged a deletion.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum TombstoneStatus {
  @JsonValue('Pending')
  pending,
  @JsonValue('Acknowledged')
  acknowledged,
}
