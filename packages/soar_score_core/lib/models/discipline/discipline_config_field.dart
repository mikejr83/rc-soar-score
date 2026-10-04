import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/config_field_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'discipline_config_field.g.dart';

/// One configurable contest setting of a discipline, with its constraints
/// and default.
///
/// System data. See `plan/data-model/entities/discipline_configfield.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DisciplineConfigField extends Equatable implements SyncScoped {
  DisciplineConfigField({
    required this.id,
    required this.disciplineProfileId,
    required String fieldKey,
    required this.fieldType,
    required String name,
    this.description,
    this.unit,
    this.required = false,
    this.defaultValue,
    List<Object?>? options,
    Map<String, Object?>? validation,
    this.displayOrder = 0,
    required DateTime createdAt,
  }) : fieldKey = requireNotBlank(fieldKey, 'fieldKey'),
       name = requireNotBlank(name, 'name'),
       options = options == null ? null : List.unmodifiable(options),
       validation = validation == null ? null : Map.unmodifiable(validation),
       createdAt = createdAt.toUtc() {
    if (options != null &&
        options.isNotEmpty &&
        fieldType != ConfigFieldType.enumeration) {
      throw ArgumentError('options are only allowed for enum fields');
    }
  }

  factory DisciplineConfigField.fromJson(Map<String, Object?> json) =>
      _$DisciplineConfigFieldFromJson(json);

  final Id id;
  final Id disciplineProfileId;

  /// Unique within the profile.
  final String fieldKey;

  final ConfigFieldType fieldType;
  final String name;
  final String? description;

  /// Unit of the value, for example `seconds`.
  final String? unit;

  /// Whether the contest must set this field.
  final bool required;

  /// A string, number, bool or enum value; not used for a landing field.
  final Object? defaultValue;

  /// Allowed values of an enum field.
  final List<Object?>? options;

  /// Constraints such as min, max or pattern.
  final Map<String, Object?>? validation;

  final int displayOrder;
  final DateTime createdAt;

  @override
  SyncScope get syncScope => SyncScope.system;

  Map<String, Object?> toJson() => _$DisciplineConfigFieldToJson(this);

  @override
  List<Object?> get props => [
    id,
    disciplineProfileId,
    fieldKey,
    fieldType,
    name,
    description,
    unit,
    required,
    defaultValue,
    options,
    validation,
    displayOrder,
    createdAt,
  ];
}
