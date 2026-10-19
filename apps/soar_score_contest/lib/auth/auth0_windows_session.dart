import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'auth_callback_listener.dart';
import 'auth_config.dart';
import 'auth_session.dart';
import 'url_scheme_registrar.dart';

final _logger = Logger('Auth0WindowsSession');

/// Windows sign-in through `auth0_flutter`'s `windowsWebAuthentication`: the
/// system browser shows Universal Login and the callback returns to the app
/// through Auth0's intermediary server pattern: Auth0 redirects the browser to
/// a short-lived loopback page ([AuthCallbackListener]) that says the window
/// can be closed and forwards to the app's custom URL scheme, which Windows
/// hands to the running app. Without a listener the redirect goes to the
/// custom scheme directly.
///
/// The SDK has no credentials manager on Windows, so the session is stored in
/// `flutter_secure_storage` (DPAPI-backed) and renewed here: when the access
/// token expires, the stored refresh token is exchanged for a new one at
/// Auth0's `/oauth/token` endpoint (public client, no secret). Auth0 rotates
/// the refresh token on every exchange, so the new one is stored before the
/// new access token is used.
///
/// Only a refusal from Auth0 (revoked, expired or reused refresh token) ends
/// the session. A network failure, a timeout or a server error keeps it, and
/// the next request tries again.
class Auth0WindowsSession extends AuthSession {
  Auth0WindowsSession(
    this._config, {
    Auth0? auth0,
    this._storage = const FlutterSecureStorage(),
    this._now = DateTime.now,
    http.Client? httpClient,
    UrlSchemeRegistrar? urlSchemeRegistrar,
    AuthCallbackListener? callbackListener,
  }) : _registrar = urlSchemeRegistrar,
       _listener = callbackListener,
       _auth0 = auth0 ?? Auth0(_config.domain, _config.clientId),
       _http = httpClient ?? http.Client();

  static const String _storageKey = 'auth0_credentials';

  /// An access token this close to expiry is treated as expired, so a request
  /// does not leave with a token that dies in flight.
  static const Duration _expiryMargin = Duration(seconds: 30);

  final Auth0Config _config;
  final Auth0 _auth0;
  final FlutterSecureStorage _storage;
  final DateTime Function() _now;
  final http.Client _http;
  final UrlSchemeRegistrar? _registrar;
  final AuthCallbackListener? _listener;
  Credentials? _credentials;
  String? _endedReason;

  /// The renewal in progress, shared by every caller that arrives meanwhile.
  /// Two exchanges of one refresh token at once would trip Auth0's reuse
  /// detection and revoke the whole token family.
  Future<void>? _renewal;

  /// No new renewal is attempted before this time after a transient failure.
  DateTime? _retryAfter;

  /// How long one renewal request may take.
  static const Duration _renewalTimeout = Duration(seconds: 10);

  /// The wait before renewal is tried again after a transient failure.
  static const Duration _retryDelay = Duration(seconds: 15);

  @override
  bool get isSignedIn => _credentials != null;

  @override
  String? get displayName =>
      _credentials?.user.name ?? _credentials?.user.email;

  @override
  String? get subject => _credentials?.user.sub;

  @override
  Uri? get pictureUrl => _credentials?.user.pictureUrl;

  @override
  String? get endedReason => _endedReason;

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
        _credentials = credentials;
        if (_isExpired(credentials)) {
          await _renewIfNeeded();
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
    _registerUrlScheme();
    await _listener?.start();
    try {
      final credentials = await _auth0.windowsWebAuthentication().login(
        appCustomURL: _config.windowsCallbackUrl,
        redirectUrl: _listener == null ? null : _config.windowsRedirectUrl,
        audience: _config.audience,
        scopes: Auth0Config.scopes,
        parameters: createAccount ? const {'screen_hint': 'signup'} : const {},
      );
      _credentials = credentials;
      _endedReason = null;
      _retryAfter = null;
      await _persist(credentials);
      notifyListeners();
    } on WebAuthenticationException catch (error) {
      _logger.info('Sign-in did not complete: ${error.code}');
      throw AuthException(
        error.code == 'USER_CANCELLED'
            ? 'Sign-in was cancelled.'
            : 'Sign-in failed: ${error.message}',
      );
    } finally {
      await _listener?.stop();
    }
  }

  /// Makes sure Windows sends the browser's callback to this executable. A
  /// failure is logged, not fatal: an installer may already have registered
  /// the scheme, and if not the sign-in times out with a clear message.
  void _registerUrlScheme() {
    try {
      _registrar?.ensureRegistered();
    } on Object catch (error, stackTrace) {
      _logger.warning('Could not register the URL scheme', error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    _credentials = null;
    _endedReason = null;
    await _deleteStored();
    notifyListeners();
    try {
      await _listener?.start();
      await _auth0.windowsWebAuthentication().logout(
        appCustomURL: _config.windowsCallbackUrl,
        returnTo: _listener == null ? null : _config.windowsLogoutReturnUrl,
      );
    } on WebAuthenticationException catch (error) {
      // The local session is already gone; only the browser session at Auth0
      // may remain.
      _logger.info('Auth0 logout did not complete: ${error.code}');
    } on AuthException catch (error) {
      _logger.info('Auth0 logout could not start: ${error.message}');
    } finally {
      await _listener?.stop();
    }
  }

  @override
  Future<String?> accessToken() async {
    if (_credentials == null) {
      return null;
    }
    if (_isExpired(_credentials!)) {
      await _renewIfNeeded();
    }
    // Still expired here means renewal failed for now: no token, but the
    // session stays so the next request can try again.
    final credentials = _credentials;
    if (credentials == null || _isExpired(credentials)) {
      return null;
    }
    return credentials.accessToken;
  }

  /// Renews the access token, or joins the renewal already running.
  Future<void> _renewIfNeeded() {
    final running = _renewal;
    if (running != null) {
      return running;
    }
    final retryAfter = _retryAfter;
    if (retryAfter != null && _now().isBefore(retryAfter)) {
      return Future.value();
    }
    return _renewal = _renew().whenComplete(() => _renewal = null);
  }

  Future<void> _renew() async {
    final current = _credentials;
    final refreshToken = current?.refreshToken;
    if (current == null) {
      return;
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      await _endSession('Your session has expired. Sign in again.');
      return;
    }

    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.https(_config.domain, '/oauth/token'),
            headers: const {'accept': 'application/json'},
            body: {
              'grant_type': 'refresh_token',
              'client_id': _config.clientId,
              'refresh_token': refreshToken,
            },
          )
          .timeout(_renewalTimeout);
    } on Object catch (error) {
      _logger.info('Could not reach Auth0 to renew the session: $error');
      _retryAfter = _now().add(_retryDelay);
      return;
    }

    if (response.statusCode >= 400 && response.statusCode < 500) {
      if (response.statusCode == 429) {
        _retryAfter = _now().add(_retryDelay);
        return;
      }
      _logger.info('Auth0 refused the refresh token: ${response.statusCode}');
      await _endSession('Your session was ended. Sign in again.');
      return;
    }

    final renewed = _parseRenewal(response, current);
    if (renewed == null) {
      _logger.warning('Auth0 answered the renewal with ${response.statusCode}');
      _retryAfter = _now().add(_retryDelay);
      return;
    }

    // Persist the rotated refresh token before the new access token is used.
    await _persist(renewed);
    _credentials = renewed;
    _retryAfter = null;
  }

  /// The credentials in a successful `/oauth/token` [response], keeping what
  /// the response leaves out (the user, and the old ID and refresh tokens
  /// when rotation is off). Null when the response is not usable.
  Credentials? _parseRenewal(http.Response response, Credentials previous) {
    if (response.statusCode != 200) {
      return null;
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        return null;
      }
      final accessToken = body['access_token'];
      final expiresIn = body['expires_in'];
      if (accessToken is! String || accessToken.isEmpty || expiresIn is! num) {
        return null;
      }
      final scope = body['scope'];
      final refreshToken = body['refresh_token'];
      final idToken = body['id_token'];
      final tokenType = body['token_type'];
      return Credentials(
        idToken: idToken is String && idToken.isNotEmpty
            ? idToken
            : previous.idToken,
        accessToken: accessToken,
        refreshToken: refreshToken is String && refreshToken.isNotEmpty
            ? refreshToken
            : previous.refreshToken,
        expiresAt: _now().add(Duration(seconds: expiresIn.toInt())),
        scopes: scope is String
            ? scope.split(' ').where((s) => s.isNotEmpty).toSet()
            : previous.scopes,
        user: previous.user,
        tokenType: tokenType is String ? tokenType : previous.tokenType,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> _endSession(String reason) async {
    _credentials = null;
    _endedReason = reason;
    await _deleteStored();
    notifyListeners();
  }

  Future<void> _persist(Credentials credentials) async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(credentials.toMap()),
      );
    } on Object catch (error, stackTrace) {
      _logger.warning('Could not store the session', error, stackTrace);
    }
  }

  Future<void> _deleteStored() async {
    try {
      await _storage.delete(key: _storageKey);
    } on Object catch (error, stackTrace) {
      _logger.warning('Could not clear the stored session', error, stackTrace);
    }
  }
}
