import 'package:json_annotation/json_annotation.dart';

/// What a landing table's entry keys mean (`LandingTable.input_unit`).
///
/// Serializes as the exact text in `plan/data-model/entities/landing_table.md`.
enum LandingInputUnit {
  @JsonValue('meters')
  meters,
  @JsonValue('feet')
  feet,
  @JsonValue('points')
  points,
}
