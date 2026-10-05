import 'package:equatable/equatable.dart';

import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';

/// Machine-readable definition of one scoring field of a profile.
///
/// Field ids and meanings are immutable within a rules version.
class ScoringFieldDefinition extends Equatable {
  ScoringFieldDefinition({
    required this.id,
    required this.label,
    required this.type,
    this.kind = ScoreFieldKind.input,
    this.unit,
    this.precision,
    this.min,
    this.max,
    this.required = false,
    List<Object?>? allowedValues,
    List<String> dependsOn = const [],
  }) : allowedValues = allowedValues == null
           ? null
           : List.unmodifiable(allowedValues),
       dependsOn = List.unmodifiable(dependsOn) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be blank');
    }
    if (precision != null && precision! < 0) {
      throw ArgumentError.value(precision, 'precision', 'must not be negative');
    }
    if (min != null && max != null && min! > max!) {
      throw ArgumentError('min must not exceed max');
    }
    if (allowedValues != null && type != ScoreFieldType.enumeration) {
      throw ArgumentError('allowedValues are only for enumeration fields');
    }
  }

  /// Stable identifier, used as the key of the field in a component set.
  final String id;

  final String label;
  final ScoreFieldType type;

  /// Whether the field is entered, a status flag, or derived by the engine.
  final ScoreFieldKind kind;

  /// Canonical unit, for example `s` or `m`.
  final String? unit;

  /// Maximum number of decimal places for numeric fields.
  final int? precision;

  /// Inclusive bounds for numeric fields.
  final num? min;
  final num? max;

  /// Required whenever the field is accepted in a submission.
  final bool required;

  /// Permitted values of an enumeration field.
  final List<Object?>? allowedValues;

  /// Ids of fields whose values this field's rules reference. Metadata for
  /// clients; the profile's combination rules enforce the behavior.
  final List<String> dependsOn;

  /// Derived fields are computed by the engine and never submitted.
  bool get acceptedInSubmission => kind != ScoreFieldKind.derived;

  @override
  List<Object?> get props => [
    id,
    label,
    type,
    kind,
    unit,
    precision,
    min,
    max,
    required,
    allowedValues,
    dependsOn,
  ];
}
