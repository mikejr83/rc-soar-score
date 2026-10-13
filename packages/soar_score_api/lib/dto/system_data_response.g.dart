// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemDataResponse _$SystemDataResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SystemDataResponse',
      json,
      ($checkedConvert) {
        final val = SystemDataResponse(
          changes: $checkedConvert(
            'changes',
            (v) => (v as List<dynamic>)
                .map((e) => SyncChangeDto.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          systemDataSeq: $checkedConvert(
            'system_data_seq',
            (v) => (v as num).toInt(),
          ),
          nextPageToken: $checkedConvert(
            'next_page_token',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'systemDataSeq': 'system_data_seq',
        'nextPageToken': 'next_page_token',
      },
    );

Map<String, dynamic> _$SystemDataResponseToJson(SystemDataResponse instance) =>
    <String, dynamic>{
      'changes': instance.changes.map((e) => e.toJson()).toList(),
      'system_data_seq': instance.systemDataSeq,
      'next_page_token': instance.nextPageToken,
    };
