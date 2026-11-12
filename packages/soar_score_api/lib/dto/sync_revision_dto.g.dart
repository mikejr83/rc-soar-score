// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_revision_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRevisionDto _$SyncRevisionDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SyncRevisionDto', json, ($checkedConvert) {
  final val = SyncRevisionDto(
    accountId: $checkedConvert(
      'account_id',
      (v) => const IdConverter().fromJson(v as String),
    ),
    sequence: $checkedConvert('sequence', (v) => (v as num).toInt()),
    contestId: $checkedConvert(
      'contest_id',
      (v) =>
          _$JsonConverterFromJson<String, Id>(v, const IdConverter().fromJson),
    ),
  );
  return val;
}, fieldKeyMap: const {'accountId': 'account_id', 'contestId': 'contest_id'});

Map<String, dynamic> _$SyncRevisionDtoToJson(SyncRevisionDto instance) =>
    <String, dynamic>{
      'account_id': const IdConverter().toJson(instance.accountId),
      'contest_id': _$JsonConverterToJson<String, Id>(
        instance.contestId,
        const IdConverter().toJson,
      ),
      'sequence': instance.sequence,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
