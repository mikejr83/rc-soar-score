import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../preferences/supported_locales.dart';
import '../../time/contest_time_zones.dart';

part 'account_preferences.g.dart';

/// Settings that follow a person between devices.
///
/// A null field means the person has not chosen: the app then uses the device
/// time zone or locale. The preferred time zone only changes times shown to
/// the director; pilot-facing times keep using the contest's zone.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
class AccountPreferences extends Equatable {
  AccountPreferences({this.preferredTimeZone, this.preferredLocale}) {
    final zone = preferredTimeZone;
    if (zone != null && !ContestTimeZones.isValid(zone)) {
      throw ArgumentError.value(zone, 'preferredTimeZone', 'Unknown time zone');
    }
    final locale = preferredLocale;
    if (locale != null && !SupportedLocales.isSupported(locale)) {
      throw ArgumentError.value(
        locale,
        'preferredLocale',
        'Unsupported locale',
      );
    }
  }

  factory AccountPreferences.fromJson(Map<String, Object?> json) =>
      _$AccountPreferencesFromJson(json);

  /// An IANA zone id such as `Europe/Rome`, or null for the device zone.
  final String? preferredTimeZone;

  /// A supported BCP 47 tag such as `en-US`, or null for the device locale.
  final String? preferredLocale;

  /// Nothing chosen yet.
  bool get isEmpty => preferredTimeZone == null && preferredLocale == null;

  /// These preferences with every field that is null here taken from [other].
  AccountPreferences orElse(AccountPreferences other) => AccountPreferences(
    preferredTimeZone: preferredTimeZone ?? other.preferredTimeZone,
    preferredLocale: preferredLocale ?? other.preferredLocale,
  );

  Map<String, Object?> toJson() => _$AccountPreferencesToJson(this);

  @override
  List<Object?> get props => [preferredTimeZone, preferredLocale];
}
