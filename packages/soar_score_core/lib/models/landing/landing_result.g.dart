// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LandingResult _$LandingResultFromJson(Map<String, dynamic> json) =>
    LandingResult(
      id: const IdConverter().fromJson(json['id'] as String),
      landingTableId: const IdConverter().fromJson(
        json['landing_table_id'] as String,
      ),
      entryKey: json['entry_key'] as String,
      displayValue: json['display_value'] as String,
      pointValue: (json['point_value'] as num).toInt(),
      ordinalPosition: (json['ordinal_position'] as num).toInt(),
    );

Map<String, dynamic> _$LandingResultToJson(LandingResult instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'landing_table_id': const IdConverter().toJson(instance.landingTableId),
      'entry_key': instance.entryKey,
      'display_value': instance.displayValue,
      'point_value': instance.pointValue,
      'ordinal_position': instance.ordinalPosition,
    };
