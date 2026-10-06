// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_contest_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateContestRequest _$UpdateContestRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateContestRequest',
  json,
  ($checkedConvert) {
    final val = UpdateContestRequest(
      baseRevision: $checkedConvert('base_revision', (v) => (v as num).toInt()),
      name: $checkedConvert('name', (v) => v as String),
      startDateTime: $checkedConvert(
        'start_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      endDateTime: $checkedConvert(
        'end_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      host: $checkedConvert('host', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseRevision': 'base_revision',
    'startDateTime': 'start_date_time',
    'endDateTime': 'end_date_time',
  },
);

Map<String, dynamic> _$UpdateContestRequestToJson(
  UpdateContestRequest instance,
) => <String, dynamic>{
  'base_revision': instance.baseRevision,
  'name': instance.name,
  'start_date_time': const UtcTimestampConverter().toJson(
    instance.startDateTime,
  ),
  'end_date_time': const UtcTimestampConverter().toJson(instance.endDateTime),
  'host': instance.host,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
};
