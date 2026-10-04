// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_public_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountPublicProfile _$AccountPublicProfileFromJson(
  Map<String, dynamic> json,
) => AccountPublicProfile(
  id: const IdConverter().fromJson(json['id'] as String),
  accountId: _$JsonConverterFromJson<String, Id>(
    json['account_id'],
    const IdConverter().fromJson,
  ),
  displayName: json['display_name'] as String,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$AccountPublicProfileToJson(
  AccountPublicProfile instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'account_id': _$JsonConverterToJson<String, Id>(
    instance.accountId,
    const IdConverter().toJson,
  ),
  'display_name': instance.displayName,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
