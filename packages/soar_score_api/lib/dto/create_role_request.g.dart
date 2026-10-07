// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_role_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateRoleRequest _$CreateRoleRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateRoleRequest', json, ($checkedConvert) {
      final val = CreateRoleRequest(
        id: $checkedConvert(
          'id',
          (v) => const IdConverter().fromJson(v as String),
        ),
        displayName: $checkedConvert('display_name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'displayName': 'display_name'});

Map<String, dynamic> _$CreateRoleRequestToJson(CreateRoleRequest instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'display_name': instance.displayName,
    };
