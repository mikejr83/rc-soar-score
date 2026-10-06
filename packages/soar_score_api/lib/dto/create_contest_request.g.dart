// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_contest_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateContestRequest _$CreateContestRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateContestRequest',
  json,
  ($checkedConvert) {
    final val = CreateContestRequest(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      name: $checkedConvert('name', (v) => v as String),
      startDateTime: $checkedConvert(
        'start_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      endDateTime: $checkedConvert(
        'end_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      timezone: $checkedConvert('timezone', (v) => v as String),
      host: $checkedConvert('host', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'startDateTime': 'start_date_time',
    'endDateTime': 'end_date_time',
  },
);

Map<String, dynamic> _$CreateContestRequestToJson(
  CreateContestRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'name': instance.name,
  'start_date_time': const UtcTimestampConverter().toJson(
    instance.startDateTime,
  ),
  'end_date_time': const UtcTimestampConverter().toJson(instance.endDateTime),
  'timezone': instance.timezone,
  'host': instance.host,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
};
