import 'package:logging/logging.dart';

import 'registry_store.dart';

final _logger = Logger('UrlSchemeRegistrar');

/// Registers the app's custom URL scheme for the current Windows user, so the
/// browser's sign-in callback (`<scheme>://callback`) starts, or is forwarded
/// to, this executable.
///
/// It writes under `HKEY_CURRENT_USER\Software\Classes\<scheme>`, which needs
/// no administrator rights, and only when the stored command differs from this
/// executable. A scheme can point at one executable per user, so a build that
/// is about to sign in takes the scheme over from any other copy of the app.
/// An installer may register the same keys (see
/// `docs/windows-installer-requirements.md`); this keeps them right when it did
/// not, and for development builds.
class UrlSchemeRegistrar {
  UrlSchemeRegistrar({
    required this._store,
    required this.scheme,
    required this.executablePath,
  });

  final RegistryStore _store;

  /// The scheme without `://`, for example `com.soarscore.contest`.
  final String scheme;

  /// Full path of the running executable.
  final String executablePath;

  String get _schemeKey => 'Software\\Classes\\$scheme';
  String get _commandKey => '$_schemeKey\\shell\\open\\command';

  /// The command Windows runs for a callback: the executable, then the URL.
  String get command => '"$executablePath" "%1"';

  /// Whether the scheme already points at [executablePath].
  bool get isRegistered =>
      _store.getString(_commandKey, '') == command &&
      _store.getString(_schemeKey, 'URL Protocol') != null;

  /// Registers the scheme for this executable unless it already is. Returns
  /// `true` when it wrote the registry, `false` when nothing needed changing.
  ///
  /// Throws if the registry cannot be written; callers decide whether that
  /// should stop sign-in.
  bool ensureRegistered() {
    if (isRegistered) {
      return false;
    }
    _logger.info('Registering the $scheme:// URL scheme for $executablePath');
    _store.setString(_schemeKey, '', 'URL:RC Soar Score');
    _store.setString(_schemeKey, 'URL Protocol', '');
    _store.setString(_commandKey, '', command);
    return true;
  }
}
