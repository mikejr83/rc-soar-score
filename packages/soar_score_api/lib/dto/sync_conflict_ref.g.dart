// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_conflict_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncConflictRef _$SyncConflictRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SyncConflictRef', json, ($checkedConvert) {
      final val = SyncConflictRef(
        id: $checkedConvert(
          'id',
          (v) => const IdConverter().fromJson(v as String),
        ),
        requiresAction: $checkedConvert('requires_action', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'requiresAction': 'requires_action'});

Map<String, dynamic> _$SyncConflictRefToJson(SyncConflictRef instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'requires_action': instance.requiresAction,
    };
