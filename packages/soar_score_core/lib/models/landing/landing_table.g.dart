// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing_table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LandingTable _$LandingTableFromJson(Map<String, dynamic> json) => LandingTable(
  id: const IdConverter().fromJson(json['id'] as String),
  ownerAccountId: _$JsonConverterFromJson<String, Id>(
    json['owner_account_id'],
    const IdConverter().fromJson,
  ),
  name: json['name'] as String,
  inputUnit: $enumDecode(_$LandingInputUnitEnumMap, json['input_unit']),
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$LandingTableToJson(LandingTable instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'owner_account_id': _$JsonConverterToJson<String, Id>(
        instance.ownerAccountId,
        const IdConverter().toJson,
      ),
      'name': instance.name,
      'input_unit': _$LandingInputUnitEnumMap[instance.inputUnit]!,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$LandingInputUnitEnumMap = {
  LandingInputUnit.meters: 'meters',
  LandingInputUnit.feet: 'feet',
  LandingInputUnit.points: 'points',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
