import 'package:json_annotation/json_annotation.dart';

/// What stage a formula serves in the calculation chain.
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_formula.md`.
enum FormulaType {
  @JsonValue('raw')
  raw,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('penalty')
  penalty,
  @JsonValue('final')
  finalFormula,
  @JsonValue('normalized')
  normalized,
}
