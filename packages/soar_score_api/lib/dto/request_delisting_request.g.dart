// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_delisting_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestDelistingRequest _$RequestDelistingRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RequestDelistingRequest', json, ($checkedConvert) {
  final val = RequestDelistingRequest(
    reason: $checkedConvert('reason', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$RequestDelistingRequestToJson(
  RequestDelistingRequest instance,
) => <String, dynamic>{'reason': instance.reason};
