// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountPreferences _$AccountPreferencesFromJson(Map<String, dynamic> json) =>
    AccountPreferences(
      preferredTimeZone: json['preferred_time_zone'] as String?,
      preferredLocale: json['preferred_locale'] as String?,
    );

Map<String, dynamic> _$AccountPreferencesToJson(AccountPreferences instance) =>
    <String, dynamic>{
      'preferred_time_zone': instance.preferredTimeZone,
      'preferred_locale': instance.preferredLocale,
    };
