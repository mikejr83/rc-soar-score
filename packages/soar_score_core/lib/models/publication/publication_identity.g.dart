// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationIdentity _$PublicationIdentityFromJson(Map<String, dynamic> json) =>
    PublicationIdentity(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: _$JsonConverterFromJson<String, Id>(
        json['contest_id'],
        const IdConverter().fromJson,
      ),
      ownerPublicProfileId: _$JsonConverterFromJson<String, Id>(
        json['owner_public_profile_id'],
        const IdConverter().fromJson,
      ),
      claimStatus:
          $enumDecodeNullable(_$ClaimStatusEnumMap, json['claim_status']) ??
          ClaimStatus.unclaimed,
      verificationEmail: json['verification_email'] as String?,
      visibility:
          $enumDecodeNullable(
            _$PublicationVisibilityEnumMap,
            json['visibility'],
          ) ??
          PublicationVisibility.unlisted,
      publishedAt: _$JsonConverterFromJson<String, DateTime>(
        json['published_at'],
        const UtcTimestampConverter().fromJson,
      ),
      currentProjectionId: _$JsonConverterFromJson<String, Id>(
        json['current_projection_id'],
        const IdConverter().fromJson,
      ),
      resultsHiddenThroughRound: (json['results_hidden_through_round'] as num?)
          ?.toInt(),
      resultsHiddenAt: _$JsonConverterFromJson<String, DateTime>(
        json['results_hidden_at'],
        const UtcTimestampConverter().fromJson,
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PublicationIdentityToJson(
  PublicationIdentity instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': _$JsonConverterToJson<String, Id>(
    instance.contestId,
    const IdConverter().toJson,
  ),
  'owner_public_profile_id': _$JsonConverterToJson<String, Id>(
    instance.ownerPublicProfileId,
    const IdConverter().toJson,
  ),
  'claim_status': _$ClaimStatusEnumMap[instance.claimStatus]!,
  'verification_email': instance.verificationEmail,
  'visibility': _$PublicationVisibilityEnumMap[instance.visibility]!,
  'published_at': _$JsonConverterToJson<String, DateTime>(
    instance.publishedAt,
    const UtcTimestampConverter().toJson,
  ),
  'current_projection_id': _$JsonConverterToJson<String, Id>(
    instance.currentProjectionId,
    const IdConverter().toJson,
  ),
  'results_hidden_through_round': instance.resultsHiddenThroughRound,
  'results_hidden_at': _$JsonConverterToJson<String, DateTime>(
    instance.resultsHiddenAt,
    const UtcTimestampConverter().toJson,
  ),
  'revision': instance.revision,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ClaimStatusEnumMap = {
  ClaimStatus.unclaimed: 'Unclaimed',
  ClaimStatus.claimed: 'Claimed',
};

const _$PublicationVisibilityEnumMap = {
  PublicationVisibility.unlisted: 'Unlisted',
  PublicationVisibility.public: 'Public',
  PublicationVisibility.delisted: 'Delisted',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
