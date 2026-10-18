// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_publication_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPublicationSummaryDto _$PublicPublicationSummaryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicPublicationSummaryDto',
  json,
  ($checkedConvert) {
    final val = PublicPublicationSummaryDto(
      publicationId: $checkedConvert(
        'publication_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      publishedAt: $checkedConvert(
        'published_at',
        (v) => DateTime.parse(v as String),
      ),
      projectionRevision: $checkedConvert(
        'projection_revision',
        (v) => (v as num).toInt(),
      ),
      contest: $checkedConvert('contest', (v) => v as Map<String, dynamic>),
      disciplineType: $checkedConvert('discipline_type', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'publicationId': 'publication_id',
    'publishedAt': 'published_at',
    'projectionRevision': 'projection_revision',
    'disciplineType': 'discipline_type',
  },
);

Map<String, dynamic> _$PublicPublicationSummaryDtoToJson(
  PublicPublicationSummaryDto instance,
) => <String, dynamic>{
  'publication_id': const IdConverter().toJson(instance.publicationId),
  'published_at': instance.publishedAt.toIso8601String(),
  'projection_revision': instance.projectionRevision,
  'contest': instance.contest,
  'discipline_type': instance.disciplineType,
};
