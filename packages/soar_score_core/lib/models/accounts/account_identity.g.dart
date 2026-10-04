// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountIdentity _$AccountIdentityFromJson(Map<String, dynamic> json) =>
    AccountIdentity(
      id: const IdConverter().fromJson(json['id'] as String),
      accountId: const IdConverter().fromJson(json['account_id'] as String),
      issuer: json['issuer'] as String,
      subject: json['subject'] as String,
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
    );

Map<String, dynamic> _$AccountIdentityToJson(AccountIdentity instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'account_id': const IdConverter().toJson(instance.accountId),
      'issuer': instance.issuer,
      'subject': instance.subject,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
    };
