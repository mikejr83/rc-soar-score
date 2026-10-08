// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_contest_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishContestRequest _$PublishContestRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublishContestRequest',
  json,
  ($checkedConvert) {
    final val = PublishContestRequest(
      clientMutationId: $checkedConvert(
        'client_mutation_id',
        (v) => v as String,
      ),
      sourceContestRevision: $checkedConvert(
        'source_contest_revision',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'clientMutationId': 'client_mutation_id',
    'sourceContestRevision': 'source_contest_revision',
  },
);

Map<String, dynamic> _$PublishContestRequestToJson(
  PublishContestRequest instance,
) => <String, dynamic>{
  'client_mutation_id': instance.clientMutationId,
  'source_contest_revision': instance.sourceContestRevision,
};
