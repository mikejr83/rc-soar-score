// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_role_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RenameRoleRequest _$RenameRoleRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RenameRoleRequest',
      json,
      ($checkedConvert) {
        final val = RenameRoleRequest(
          baseRevision: $checkedConvert(
            'base_revision',
            (v) => (v as num).toInt(),
          ),
          displayName: $checkedConvert('display_name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'baseRevision': 'base_revision',
        'displayName': 'display_name',
      },
    );

Map<String, dynamic> _$RenameRoleRequestToJson(RenameRoleRequest instance) =>
    <String, dynamic>{
      'base_revision': instance.baseRevision,
      'display_name': instance.displayName,
    };
