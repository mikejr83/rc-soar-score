// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  contestParticipationId: const IdConverter().fromJson(
    json['contest_participation_id'] as String,
  ),
  type:
      $enumDecodeNullable(_$InvitationTypeEnumMap, json['type']) ??
      InvitationType.magicUrl,
  protectedCredential: const ProtectedCredentialConverter().fromJson(
    json['protected_credential'] as String,
  ),
  invitationRevision: (json['invitation_revision'] as num?)?.toInt() ?? 1,
  state:
      $enumDecodeNullable(_$InvitationStateEnumMap, json['state']) ??
      InvitationState.active,
  audience:
      $enumDecodeNullable(_$InvitationAudienceEnumMap, json['audience']) ??
      InvitationAudience.pilot,
  issuedBy: const IdConverter().fromJson(json['issued_by'] as String),
  issuedAt: const UtcTimestampConverter().fromJson(json['issued_at'] as String),
  expiresAt: _$JsonConverterFromJson<String, DateTime>(
    json['expires_at'],
    const UtcTimestampConverter().fromJson,
  ),
  firstUsedAt: _$JsonConverterFromJson<String, DateTime>(
    json['first_used_at'],
    const UtcTimestampConverter().fromJson,
  ),
  lastUsedAt: _$JsonConverterFromJson<String, DateTime>(
    json['last_used_at'],
    const UtcTimestampConverter().fromJson,
  ),
  revokedAt: _$JsonConverterFromJson<String, DateTime>(
    json['revoked_at'],
    const UtcTimestampConverter().fromJson,
  ),
  replacesInvitationId: _$JsonConverterFromJson<String, Id>(
    json['replaces_invitation_id'],
    const IdConverter().fromJson,
  ),
  redeemedByAccountId: _$JsonConverterFromJson<String, Id>(
    json['redeemed_by_account_id'],
    const IdConverter().fromJson,
  ),
  deliveryOutcomes:
      (json['delivery_outcomes'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  clientMutationId: json['client_mutation_id'] as String,
);

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'contest_participation_id': const IdConverter().toJson(
        instance.contestParticipationId,
      ),
      'type': _$InvitationTypeEnumMap[instance.type]!,
      'protected_credential': const ProtectedCredentialConverter().toJson(
        instance.protectedCredential,
      ),
      'invitation_revision': instance.invitationRevision,
      'state': _$InvitationStateEnumMap[instance.state]!,
      'audience': _$InvitationAudienceEnumMap[instance.audience]!,
      'issued_by': const IdConverter().toJson(instance.issuedBy),
      'issued_at': const UtcTimestampConverter().toJson(instance.issuedAt),
      'expires_at': _$JsonConverterToJson<String, DateTime>(
        instance.expiresAt,
        const UtcTimestampConverter().toJson,
      ),
      'first_used_at': _$JsonConverterToJson<String, DateTime>(
        instance.firstUsedAt,
        const UtcTimestampConverter().toJson,
      ),
      'last_used_at': _$JsonConverterToJson<String, DateTime>(
        instance.lastUsedAt,
        const UtcTimestampConverter().toJson,
      ),
      'revoked_at': _$JsonConverterToJson<String, DateTime>(
        instance.revokedAt,
        const UtcTimestampConverter().toJson,
      ),
      'replaces_invitation_id': _$JsonConverterToJson<String, Id>(
        instance.replacesInvitationId,
        const IdConverter().toJson,
      ),
      'redeemed_by_account_id': _$JsonConverterToJson<String, Id>(
        instance.redeemedByAccountId,
        const IdConverter().toJson,
      ),
      'delivery_outcomes': instance.deliveryOutcomes,
      'client_mutation_id': instance.clientMutationId,
    };

const _$InvitationTypeEnumMap = {
  InvitationType.magicUrl: 'MagicURL',
  InvitationType.qrCode: 'QRCode',
};

const _$InvitationStateEnumMap = {
  InvitationState.active: 'Active',
  InvitationState.replaced: 'Replaced',
  InvitationState.revoked: 'Revoked',
  InvitationState.expired: 'Expired',
};

const _$InvitationAudienceEnumMap = {
  InvitationAudience.pilot: 'Pilot',
  InvitationAudience.helper: 'Helper',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
