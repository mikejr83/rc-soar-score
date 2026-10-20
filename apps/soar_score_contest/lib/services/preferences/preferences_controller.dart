import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

final _logger = Logger('PreferencesController');

/// How a change to the preferences ended.
enum SaveResult {
  /// Stored on the account.
  saved,

  /// Not stored because nobody is signed in; the change applies until the app
  /// is closed.
  needsSignIn,

  /// Not stored because the save failed; the change applies until the app is
  /// closed.
  failed,
}

/// Thrown by a save when the preferences can only be kept on an account and
/// nobody is signed in.
class SignInRequiredError implements Exception {
  const SignInRequiredError();

  @override
  String toString() => 'Sign in to save preferences';
}

/// The account's preferred time zone and locale, as the app uses them.
///
/// [locale] is `null` until a supported locale is chosen, which leaves the
/// choice to the device: Flutter then picks the best supported match for the
/// device locale and falls back to the first supported one (`en`, whose
/// messages are the en-US text). A preference that is not supported (a locale
/// removed later) counts as unset. [timeZone] is `null` to follow the device.
///
/// A change applies at once and is then saved through [savePreferences].
/// Saves run one after another, each writing the choices as they are when it
/// runs, so an older save can never overwrite a newer choice, and none starts
/// before the first [load] has finished, so a choice made while the account's
/// preferences are still loading does not clear the other one.
class PreferencesController extends ChangeNotifier {
  PreferencesController({
    this.loadPreferences,
    this.savePreferences,
    Stream<void>? changes,
    bool Function(String tag)? isSupported,
  }) : _isSupported = isSupported ?? core.SupportedLocales.isSupported {
    _changes = changes?.listen((_) => unawaited(_read(initial: false)));
  }

  /// Reads the account's preferences; `null` leaves them unset.
  final Future<core.AccountPreferences> Function()? loadPreferences;

  /// Stores the account's preferences; `null` keeps them for this run only.
  /// Throws [SignInRequiredError] when nobody is signed in.
  final Future<void> Function(core.AccountPreferences preferences)?
  savePreferences;

  final bool Function(String tag) _isSupported;
  StreamSubscription<void>? _changes;
  String? _timeZone;
  String? _localeTag;
  Future<void>? _loading;
  int _zoneEdits = 0;
  int _localeEdits = 0;
  int _pending = 0;
  int _savesDone = 0;
  Future<void> _tail = Future.value();
  bool _disposed = false;

  /// The preferred IANA time zone for times shown to the director, or `null`
  /// to follow the device.
  String? get timeZone => _timeZone;

  /// The preferred locale tag (such as `en-US`), or `null` to follow the
  /// device.
  String? get localeTag => _localeTag;

  /// The preferred locale, or `null` to follow the device.
  Locale? get locale => localeFor(_localeTag);

  /// Reads the preferences from the account (the first read; later changes to
  /// the account's preferences arrive through `changes`). Choices made while
  /// it runs are kept.
  Future<void> load() => _loading ??= _read(initial: true);

  Future<void> _read({required bool initial}) async {
    final loader = loadPreferences;
    if (loader == null) return;
    final zoneEdits = _zoneEdits;
    final localeEdits = _localeEdits;
    final savesDone = _savesDone;
    final core.AccountPreferences preferences;
    try {
      preferences = await loader();
    } on Object catch (error) {
      _logger.warning('The preferences could not be read: $error');
      return;
    }
    if (_disposed) return;
    // An answer read before a save finished, or while one is in flight, may
    // predate it, so a later read gives way to the saves. The first read only
    // fills in what was not chosen while it ran, field by field.
    if (!initial && (_pending > 0 || _savesDone != savesDone)) return;
    _assign(
      _zoneEdits != zoneEdits ? _timeZone : preferences.preferredTimeZone,
      _localeEdits != localeEdits ? _localeTag : preferences.preferredLocale,
    );
  }

  /// Applies [tag] (a BCP 47 tag such as `en-US`, or `null` for the device
  /// locale) now and saves it.
  Future<SaveResult> setLocale(String? tag) {
    _localeEdits++;
    _assign(_timeZone, tag);
    return _enqueueSave();
  }

  /// Applies [zoneId] (an IANA id, or `null` for the device zone) now and
  /// saves it.
  Future<SaveResult> setTimeZone(String? zoneId) {
    _zoneEdits++;
    _assign(zoneId, _localeTag);
    return _enqueueSave();
  }

  Future<SaveResult> _enqueueSave() {
    _pending++;
    final result = _tail.then((_) async {
      await _loading;
      return _saveNow();
    });
    _tail = result.then((_) {});
    return result.whenComplete(() {
      _pending--;
      _savesDone++;
    });
  }

  Future<SaveResult> _saveNow() async {
    final save = savePreferences;
    if (save == null) return SaveResult.saved;
    try {
      await save(
        core.AccountPreferences(
          preferredTimeZone: _timeZone,
          preferredLocale: _localeTag,
        ),
      );
      return SaveResult.saved;
    } on SignInRequiredError {
      return SaveResult.needsSignIn;
    } on Object catch (error) {
      _logger.warning('The preferences could not be saved: $error');
      return SaveResult.failed;
    }
  }

  void _assign(String? zone, String? tag) {
    final nextZone = zone != null && core.ContestTimeZones.isValid(zone)
        ? zone
        : null;
    final nextTag = tag != null && _isSupported(tag) ? tag : null;
    if (nextZone == _timeZone && nextTag == _localeTag) return;
    _timeZone = nextZone;
    _localeTag = nextTag;
    if (!_disposed) notifyListeners();
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
    unawaited(_changes?.cancel());
    super.dispose();
  }
}
