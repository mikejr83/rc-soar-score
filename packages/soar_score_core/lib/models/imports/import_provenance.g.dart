// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_provenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportProvenance _$ImportProvenanceFromJson(Map<String, dynamic> json) =>
    ImportProvenance(
      id: const IdConverter().fromJson(json['id'] as String),
      ownerAccountId: const IdConverter().fromJson(
        json['owner_account_id'] as String,
      ),
      contestId: _$JsonConverterFromJson<String, Id>(
        json['contest_id'],
        const IdConverter().fromJson,
      ),
      stampedEntityType: json['stamped_entity_type'] as String,
      stampedEntityId: const IdConverter().fromJson(
        json['stamped_entity_id'] as String,
      ),
      sourceSystem: json['source_system'] as String,
      sourceKeys: json['source_keys'] as Map<String, dynamic>,
      sourceValues: json['source_values'] as Map<String, dynamic>?,
      fileFingerprint: json['file_fingerprint'] as String,
      dedupeKey: json['dedupe_key'] as String?,
      importOperationId: const IdConverter().fromJson(
        json['import_operation_id'] as String,
      ),
      toolVersion: json['tool_version'] as String,
      importedAt: const UtcTimestampConverter().fromJson(
        json['imported_at'] as String,
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ImportProvenanceToJson(
  ImportProvenance instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'owner_account_id': const IdConverter().toJson(instance.ownerAccountId),
  'contest_id': _$JsonConverterToJson<String, Id>(
    instance.contestId,
    const IdConverter().toJson,
  ),
  'stamped_entity_type': instance.stampedEntityType,
  'stamped_entity_id': const IdConverter().toJson(instance.stampedEntityId),
  'source_system': instance.sourceSystem,
  'source_keys': instance.sourceKeys,
  'source_values': instance.sourceValues,
  'file_fingerprint': instance.fileFingerprint,
  'dedupe_key': instance.dedupeKey,
  'import_operation_id': const IdConverter().toJson(instance.importOperationId),
  'tool_version': instance.toolVersion,
  'imported_at': const UtcTimestampConverter().toJson(instance.importedAt),
  'revision': instance.revision,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
