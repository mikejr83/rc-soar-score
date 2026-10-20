import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

/// The locale the app shows, from the account's preferred locale.
///
/// [locale] is `null` until a supported locale is chosen, which leaves the
/// choice to the device: Flutter then picks the best supported match for the
/// device locale and falls back to the first supported one (`en`, whose
/// messages are the en-US text). A preference that is not supported (a locale
/// removed later) counts as unset.
class LocaleController extends ChangeNotifier {
  LocaleController({
    this.loadPreferences,
    bool Function(String tag)? isSupported,
  }) : _isSupported = isSupported ?? core.SupportedLocales.isSupported;

  final bool Function(String tag) _isSupported;

  /// Reads the account's preferences; `null` follows the device.
  final Future<core.AccountPreferences> Function()? loadPreferences;

  Locale? _locale;
  bool _disposed = false;

  /// The preferred locale, or `null` to follow the device.
  Locale? get locale => _locale;

  /// Reads the preferred locale from the account.
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
    setPreferred(preferences.preferredLocale);
  }

  /// Applies [tag] (a BCP 47 tag such as `en-US`, or `null` for the device
  /// locale) now.
  void setPreferred(String? tag) {
    final next = localeFor(tag);
    if (next == _locale) return;
    _locale = next;
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
