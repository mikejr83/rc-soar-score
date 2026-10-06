// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_configuration_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveConfigurationRequest _$SaveConfigurationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SaveConfigurationRequest',
  json,
  ($checkedConvert) {
    final val = SaveConfigurationRequest(
      baseRevisionNumber: $checkedConvert(
        'base_revision_number',
        (v) => (v as num).toInt(),
      ),
      disciplineProfileId: $checkedConvert(
        'discipline_profile_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      config: $checkedConvert(
        'config',
        (v) => _configFromJson(v as Map<String, dynamic>),
      ),
      landingTableId: $checkedConvert(
        'landing_table_id',
        (v) => _$JsonConverterFromJson<String, Id>(
          v,
          const IdConverter().fromJson,
        ),
      ),
      notes: $checkedConvert('notes', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseRevisionNumber': 'base_revision_number',
    'disciplineProfileId': 'discipline_profile_id',
    'landingTableId': 'landing_table_id',
  },
);

Map<String, dynamic> _$SaveConfigurationRequestToJson(
  SaveConfigurationRequest instance,
) => <String, dynamic>{
  'base_revision_number': instance.baseRevisionNumber,
  'discipline_profile_id': const IdConverter().toJson(
    instance.disciplineProfileId,
  ),
  'config': _configToJson(instance.config),
  'landing_table_id': _$JsonConverterToJson<String, Id>(
    instance.landingTableId,
    const IdConverter().toJson,
  ),
  'notes': instance.notes,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
