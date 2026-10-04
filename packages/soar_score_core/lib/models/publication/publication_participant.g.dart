// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationParticipant _$PublicationParticipantFromJson(
  Map<String, dynamic> json,
) => PublicationParticipant(
  id: const IdConverter().fromJson(json['id'] as String),
  publicationId: const IdConverter().fromJson(json['publication_id'] as String),
  pilotKey: json['pilot_key'] as String,
  sourceParticipationId: _$JsonConverterFromJson<String, Id>(
    json['source_participation_id'],
    const IdConverter().fromJson,
  ),
  details: json['details'] as Map<String, dynamic>?,
  publicProfileId: _$JsonConverterFromJson<String, Id>(
    json['public_profile_id'],
    const IdConverter().fromJson,
  ),
  redactedAt: _$JsonConverterFromJson<String, DateTime>(
    json['redacted_at'],
    const UtcTimestampConverter().fromJson,
  ),
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  updatedAt: const UtcTimestampConverter().fromJson(
    json['updated_at'] as String,
  ),
);

Map<String, dynamic> _$PublicationParticipantToJson(
  PublicationParticipant instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'publication_id': const IdConverter().toJson(instance.publicationId),
  'pilot_key': instance.pilotKey,
  'source_participation_id': _$JsonConverterToJson<String, Id>(
    instance.sourceParticipationId,
    const IdConverter().toJson,
  ),
  'details': instance.details,
  'public_profile_id': _$JsonConverterToJson<String, Id>(
    instance.publicProfileId,
    const IdConverter().toJson,
  ),
  'redacted_at': _$JsonConverterToJson<String, DateTime>(
    instance.redactedAt,
    const UtcTimestampConverter().toJson,
  ),
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
