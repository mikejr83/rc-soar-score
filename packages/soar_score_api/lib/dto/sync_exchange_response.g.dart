// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_exchange_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncExchangeResponse _$SyncExchangeResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SyncExchangeResponse',
  json,
  ($checkedConvert) {
    final val = SyncExchangeResponse(
      protocolVersion: $checkedConvert(
        'protocol_version',
        (v) => (v as num).toInt(),
      ),
      results: $checkedConvert(
        'results',
        (v) => (v as List<dynamic>)
            .map((e) => SyncMutationResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      changes: $checkedConvert(
        'changes',
        (v) => (v as List<dynamic>)
            .map((e) => SyncChangeDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      conflicts: $checkedConvert(
        'conflicts',
        (v) => (v as List<dynamic>)
            .map((e) => SyncConflictRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      serverSequence: $checkedConvert(
        'server_sequence',
        (v) => (v as num).toInt(),
      ),
      nextPageToken: $checkedConvert('next_page_token', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'protocolVersion': 'protocol_version',
    'serverSequence': 'server_sequence',
    'nextPageToken': 'next_page_token',
  },
);

Map<String, dynamic> _$SyncExchangeResponseToJson(
  SyncExchangeResponse instance,
) => <String, dynamic>{
  'protocol_version': instance.protocolVersion,
  'results': instance.results.map((e) => e.toJson()).toList(),
  'changes': instance.changes.map((e) => e.toJson()).toList(),
  'conflicts': instance.conflicts.map((e) => e.toJson()).toList(),
  'next_page_token': instance.nextPageToken,
  'server_sequence': instance.serverSequence,
};
