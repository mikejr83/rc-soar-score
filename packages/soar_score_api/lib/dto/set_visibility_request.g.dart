// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_visibility_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetVisibilityRequest _$SetVisibilityRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetVisibilityRequest', json, ($checkedConvert) {
  final val = SetVisibilityRequest(
    visibility: $checkedConvert('visibility', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$SetVisibilityRequestToJson(
  SetVisibilityRequest instance,
) => <String, dynamic>{'visibility': instance.visibility};
