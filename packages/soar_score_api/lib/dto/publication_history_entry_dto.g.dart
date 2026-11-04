// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_history_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationHistoryEntryDto _$PublicationHistoryEntryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicationHistoryEntryDto',
  json,
  ($checkedConvert) {
    final val = PublicationHistoryEntryDto(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      projectionRevision: $checkedConvert(
        'projection_revision',
        (v) => (v as num).toInt(),
      ),
      contestRevision: $checkedConvert(
        'contest_revision',
        (v) => (v as num).toInt(),
      ),
      publishedAt: $checkedConvert(
        'published_at',
        (v) => DateTime.parse(v as String),
      ),
      publishedBy: $checkedConvert(
        'published_by',
        (v) => _$JsonConverterFromJson<String, Id>(
          v,
          const IdConverter().fromJson,
        ),
      ),
      publisherKind: $checkedConvert('publisher_kind', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'projectionRevision': 'projection_revision',
    'contestRevision': 'contest_revision',
    'publishedAt': 'published_at',
    'publishedBy': 'published_by',
    'publisherKind': 'publisher_kind',
  },
);

Map<String, dynamic> _$PublicationHistoryEntryDtoToJson(
  PublicationHistoryEntryDto instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'projection_revision': instance.projectionRevision,
  'contest_revision': instance.contestRevision,
  'published_at': instance.publishedAt.toIso8601String(),
  'published_by': _$JsonConverterToJson<String, Id>(
    instance.publishedBy,
    const IdConverter().toJson,
  ),
  'publisher_kind': instance.publisherKind,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
