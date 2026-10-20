import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

/// The account's preferred time zone and locale, as the app uses them.
///
/// [locale] is `null` until a supported locale is chosen, which leaves the
/// choice to the device: Flutter then picks the best supported match for the
/// device locale and falls back to the first supported one (`en`, whose
/// messages are the en-US text). A preference that is not supported (a locale
/// removed later) counts as unset. [timeZone] is `null` to follow the device.
///
/// A change applies at once and is then saved through [savePreferences]; if
/// the save fails the change still applies until the app is closed.
class PreferencesController extends ChangeNotifier {
  PreferencesController({
    this.loadPreferences,
    this.savePreferences,
    bool Function(String tag)? isSupported,
  }) : _isSupported = isSupported ?? core.SupportedLocales.isSupported;

  /// Reads the account's preferences; `null` leaves them unset.
  final Future<core.AccountPreferences> Function()? loadPreferences;

  /// Stores the account's preferences; `null` keeps them for this run only.
  final Future<void> Function(core.AccountPreferences preferences)?
  savePreferences;

  final bool Function(String tag) _isSupported;
  String? _timeZone;
  String? _localeTag;
  bool _disposed = false;

  /// The preferred IANA time zone for times shown to the director, or `null`
  /// to follow the device.
  String? get timeZone => _timeZone;

  /// The preferred locale tag (such as `en-US`), or `null` to follow the
  /// device.
  String? get localeTag => _localeTag;

  /// The preferred locale, or `null` to follow the device.
  Locale? get locale => localeFor(_localeTag);

  /// Reads the preferences from the account.
  Future<void> load() async {
    final loader = loadPreferences;
    if (loader == null) return;
    final core.AccountPreferences preferences;
    try {
      preferences = await loader();
    } on Object {
      return;
    }
    if (_disposed) return;
    _apply(preferences.preferredTimeZone, preferences.preferredLocale);
  }

  /// Applies [tag] (a BCP 47 tag such as `en-US`, or `null` for the device
  /// locale) now and saves it. Returns `false` if the save failed.
  Future<bool> setLocale(String? tag) =>
      _change(_timeZone, tag != null && _isSupported(tag) ? tag : null);

  /// Applies [zoneId] (an IANA id, or `null` for the device zone) now and
  /// saves it. Returns `false` if the save failed.
  Future<bool> setTimeZone(String? zoneId) => _change(zoneId, _localeTag);

  Future<bool> _change(String? zone, String? tag) async {
    _apply(zone, tag);
    final save = savePreferences;
    if (save == null) return true;
    try {
      await save(
        core.AccountPreferences(
          preferredTimeZone: _timeZone,
          preferredLocale: _localeTag,
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }

  void _apply(String? zone, String? tag) {
    final nextZone = zone != null && core.ContestTimeZones.isValid(zone)
        ? zone
        : null;
    final nextTag = tag != null && _isSupported(tag) ? tag : null;
    if (nextZone == _timeZone && nextTag == _localeTag) return;
    _timeZone = nextZone;
    _localeTag = nextTag;
    notifyListeners();
  }

  /// The [Locale] for a supported [tag], or `null`.
  Locale? localeFor(String? tag) {
    if (tag == null || !_isSupported(tag)) return null;
    final parts = tag.split('-');
    return Locale.fromSubtags(
      languageCode: parts.first,
      countryCode: parts.length > 1 ? parts[1] : null,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
