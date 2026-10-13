import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import 'auth_config.dart';
import 'auth_session.dart';

final _logger = Logger('Auth0WindowsSession');

/// Windows sign-in through `auth0_flutter`'s `windowsWebAuthentication`: the
/// system browser shows Universal Login and Windows hands the callback URL
/// (a custom scheme) back to the running app.
///
/// The SDK has no credentials manager on Windows, so the session is stored in
/// `flutter_secure_storage` (DPAPI-backed) and there is no token renewal: an
/// expired access token ends the session and the user signs in again.
class Auth0WindowsSession extends AuthSession {
  Auth0WindowsSession(
    this._config, {
    Auth0? auth0,
    this._storage = const FlutterSecureStorage(),
    this._now = DateTime.now,
  }) : _auth0 = auth0 ?? Auth0(_config.domain, _config.clientId);

  static const String _storageKey = 'auth0_credentials';

  /// An access token this close to expiry is treated as expired, so a request
  /// does not leave with a token that dies in flight.
  static const Duration _expiryMargin = Duration(seconds: 30);

  final Auth0Config _config;
  final Auth0 _auth0;
  final FlutterSecureStorage _storage;
  final DateTime Function() _now;
  Credentials? _credentials;

  @override
  bool get isSignedIn => _credentials != null;

  @override
  String? get displayName =>
      _credentials?.user.name ?? _credentials?.user.email;

  bool _isExpired(Credentials credentials) =>
      !credentials.expiresAt.isAfter(_now().add(_expiryMargin));

  @override
  Future<void> restore() async {
    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored != null) {
        final credentials = Credentials.fromMap(
          jsonDecode(stored) as Map<String, dynamic>,
        );
        if (_isExpired(credentials)) {
          await _storage.delete(key: _storageKey);
        } else {
          _credentials = credentials;
        }
      }
    } on Object catch (error, stackTrace) {
      // Unreadable or from an older schema: drop it and start signed out.
      _logger.warning('Dropping the stored Auth0 session', error, stackTrace);
      _credentials = null;
      await _deleteStored();
    }
    notifyListeners();
  }

  @override
  Future<void> signIn({bool createAccount = false}) async {
    try {
      final credentials = await _auth0.windowsWebAuthentication().login(
        appCustomURL: _config.windowsCallbackUrl,
        audience: _config.audience,
        scopes: Auth0Config.scopes,
        parameters: createAccount ? const {'screen_hint': 'signup'} : const {},
      );
      _credentials = credentials;
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(credentials.toMap()),
      );
      notifyListeners();
    } on WebAuthenticationException catch (error) {
      _logger.info('Sign-in did not complete: ${error.code}');
      throw AuthException(
        error.code == 'USER_CANCELLED'
            ? 'Sign-in was cancelled.'
            : 'Sign-in failed: ${error.message}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _credentials = null;
    await _deleteStored();
    notifyListeners();
    try {
      await _auth0.windowsWebAuthentication().logout(
        appCustomURL: _config.windowsCallbackUrl,
      );
    } on WebAuthenticationException catch (error) {
      // The local session is already gone; only the browser session at Auth0
      // may remain.
      _logger.info('Auth0 logout did not complete: ${error.code}');
    }
  }

  @override
  Future<String?> accessToken() async {
    final credentials = _credentials;
    if (credentials == null) {
      return null;
    }
    if (_isExpired(credentials)) {
      _credentials = null;
      await _deleteStored();
      notifyListeners();
      return null;
    }
    return credentials.accessToken;
  }

  Future<void> _deleteStored() async {
    try {
      await _storage.delete(key: _storageKey);
    } on Object catch (error, stackTrace) {
      _logger.warning('Could not clear the stored session', error, stackTrace);
    }
  }
}
