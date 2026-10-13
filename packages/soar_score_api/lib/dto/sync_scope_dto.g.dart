// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_scope_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncScopeDto _$SyncScopeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SyncScopeDto',
      json,
      ($checkedConvert) {
        final val = SyncScopeDto(
          contestId: $checkedConvert(
            'contest_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
          ownerAccountId: $checkedConvert(
            'owner_account_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'contestId': 'contest_id',
        'ownerAccountId': 'owner_account_id',
      },
    );

Map<String, dynamic> _$SyncScopeDtoToJson(SyncScopeDto instance) =>
    <String, dynamic>{
      'contest_id': ?_$JsonConverterToJson<String, Id>(
        instance.contestId,
        const IdConverter().toJson,
      ),
      'owner_account_id': ?_$JsonConverterToJson<String, Id>(
        instance.ownerAccountId,
        const IdConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
