// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_exchange_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncExchangeRequest _$SyncExchangeRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SyncExchangeRequest',
      json,
      ($checkedConvert) {
        final val = SyncExchangeRequest(
          protocolVersion: $checkedConvert(
            'protocol_version',
            (v) => (v as num).toInt(),
          ),
          schemaVersion: $checkedConvert(
            'schema_version',
            (v) => (v as num).toInt(),
          ),
          installationId: $checkedConvert(
            'installation_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          scope: $checkedConvert(
            'scope',
            (v) => SyncScopeDto.fromJson(v as Map<String, dynamic>),
          ),
          lastAcknowledgedSequence: $checkedConvert(
            'last_acknowledged_sequence',
            (v) => (v as num).toInt(),
          ),
          pageToken: $checkedConvert('page_token', (v) => v as String?),
          mutations: $checkedConvert(
            'mutations',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) =>
                          SyncMutationDto.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'protocolVersion': 'protocol_version',
        'schemaVersion': 'schema_version',
        'installationId': 'installation_id',
        'lastAcknowledgedSequence': 'last_acknowledged_sequence',
        'pageToken': 'page_token',
      },
    );

Map<String, dynamic> _$SyncExchangeRequestToJson(
  SyncExchangeRequest instance,
) => <String, dynamic>{
  'protocol_version': instance.protocolVersion,
  'schema_version': instance.schemaVersion,
  'installation_id': const IdConverter().toJson(instance.installationId),
  'scope': instance.scope.toJson(),
  'last_acknowledged_sequence': instance.lastAcknowledgedSequence,
  'page_token': instance.pageToken,
  'mutations': instance.mutations.map((e) => e.toJson()).toList(),
};
