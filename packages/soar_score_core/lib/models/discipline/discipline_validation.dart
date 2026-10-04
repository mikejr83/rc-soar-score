import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'discipline_validation.g.dart';

/// A cross-field constraint between score-entry fields.
///
/// System data. See `plan/data-model/entities/discipline_validation.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DisciplineValidation extends Equatable implements SyncScoped {
  DisciplineValidation({
    required this.id,
    required this.disciplineProfileId,
    required List<String> fieldKeys,
    required String constraintType,
    this.description,
    this.appliesTo,
    this.message,
    this.displayOrder = 0,
    required DateTime createdAt,
  }) : fieldKeys = List.unmodifiable(fieldKeys),
       constraintType = requireNotBlank(constraintType, 'constraintType'),
       createdAt = createdAt.toUtc() {
    if (fieldKeys.length < 2) {
      throw ArgumentError.value(fieldKeys, 'fieldKeys', 'needs at least two');
    }
  }

  factory DisciplineValidation.fromJson(Map<String, Object?> json) =>
      _$DisciplineValidationFromJson(json);

  final Id id;
  final Id disciplineProfileId;

  /// The score field keys the constraint applies to; at least two.
  final List<String> fieldKeys;

  /// For example `required_if`, `mutually_exclusive`, `less_than`.
  final String constraintType;

  final String? description;

  /// Target values and field names specific to this constraint.
  final Object? appliesTo;

  /// User-facing error message when validation fails.
  final String? message;

  final int displayOrder;
  final DateTime createdAt;

  @override
  SyncScope get syncScope => SyncScope.system;

  Map<String, Object?> toJson() => _$DisciplineValidationToJson(this);

  @override
  List<Object?> get props => [
    id,
    disciplineProfileId,
    fieldKeys,
    constraintType,
    description,
    appliesTo,
    message,
    displayOrder,
    createdAt,
  ];
}
