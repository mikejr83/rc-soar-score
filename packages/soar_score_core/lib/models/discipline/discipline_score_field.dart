import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'discipline_score_field.g.dart';

/// One score-entry field of a discipline, including zero-reason semantics.
///
/// System data. See `plan/data-model/entities/discipline_scorefield.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DisciplineScoreField extends Equatable implements SyncScoped {
  DisciplineScoreField({
    required this.id,
    required this.disciplineProfileId,
    required String fieldKey,
    required this.fieldType,
    required String name,
    this.description,
    this.fieldKind = ScoreFieldKind.input,
    this.unit,
    this.precision,
    this.required = false,
    this.defaultValue,
    List<Object?>? options,
    Map<String, Object?>? validation,
    this.displayOrder = 0,
    this.isZeroReason = false,
    this.zeroReasonCode,
    required DateTime createdAt,
  }) : fieldKey = requireNotBlank(fieldKey, 'fieldKey'),
       name = requireNotBlank(name, 'name'),
       options = options == null ? null : List.unmodifiable(options),
       validation = validation == null ? null : Map.unmodifiable(validation),
       createdAt = createdAt.toUtc() {
    if (options != null &&
        options.isNotEmpty &&
        fieldType != ScoreFieldType.enumeration) {
      throw ArgumentError('options are only allowed for enum fields');
    }
    if (precision != null) requireNonNegative(precision!, 'precision');
    if (isZeroReason && (zeroReasonCode == null || zeroReasonCode!.isEmpty)) {
      throw ArgumentError('a zero-reason field needs a zero_reason_code');
    }
  }

  factory DisciplineScoreField.fromJson(Map<String, Object?> json) =>
      _$DisciplineScoreFieldFromJson(json);

  final Id id;
  final Id disciplineProfileId;

  /// Unique within the profile.
  final String fieldKey;

  final ScoreFieldType fieldType;
  final String name;
  final String? description;

  /// Whether the scorer enters it, it is a status flag, or it is derived.
  /// A derived field is never accepted in a score submission.
  final ScoreFieldKind fieldKind;

  /// Unit of the canonical stored value, for example `seconds`.
  final String? unit;

  /// Decimal places kept in the canonical value.
  final int? precision;

  final bool required;
  final Object? defaultValue;
  final List<Object?>? options;
  final Map<String, Object?>? validation;
  final int displayOrder;

  /// Whether the field represents a zero-score condition.
  final bool isZeroReason;

  /// The `rule_key` of the matching zero rule in the same profile.
  final String? zeroReasonCode;

  final DateTime createdAt;

  /// Whether a score submission may include this field.
  bool get acceptedInSubmission => fieldKind != ScoreFieldKind.derived;

  @override
  SyncScope get syncScope => SyncScope.system;

  Map<String, Object?> toJson() => _$DisciplineScoreFieldToJson(this);

  @override
  List<Object?> get props => [
    id,
    disciplineProfileId,
    fieldKey,
    fieldType,
    name,
    description,
    fieldKind,
    unit,
    precision,
    required,
    defaultValue,
    options,
    validation,
    displayOrder,
    isZeroReason,
    zeroReasonCode,
    createdAt,
  ];
}
