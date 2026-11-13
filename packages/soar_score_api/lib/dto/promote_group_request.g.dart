// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promote_group_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoteGroupRequest _$PromoteGroupRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromoteGroupRequest', json, ($checkedConvert) {
      final val = PromoteGroupRequest(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PromoteGroupItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PromoteGroupRequestToJson(
  PromoteGroupRequest instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
