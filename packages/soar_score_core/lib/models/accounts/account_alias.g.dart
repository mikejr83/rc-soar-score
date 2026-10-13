// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_alias.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountAlias _$AccountAliasFromJson(Map<String, dynamic> json) => AccountAlias(
  id: const IdConverter().fromJson(json['id'] as String),
  accountId: const IdConverter().fromJson(json['account_id'] as String),
  claimedAt: const UtcTimestampConverter().fromJson(
    json['claimed_at'] as String,
  ),
);

Map<String, dynamic> _$AccountAliasToJson(AccountAlias instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'account_id': const IdConverter().toJson(instance.accountId),
      'claimed_at': const UtcTimestampConverter().toJson(instance.claimedAt),
    };
