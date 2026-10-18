import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:logging/logging.dart';

import 'auth_config.dart';
import 'auth_session.dart';

final _logger = Logger('Auth0WebSession');

/// Web sign-in through Auth0's SPA SDK (redirect flow with PKCE).
///
/// `signIn` leaves the page for Universal Login; Auth0 returns to the app's
/// origin with a code, and [restore] (run before the first frame) exchanges
/// it. The SDK keeps the session in local storage and renews access tokens
/// with a refresh token.
class Auth0WebSession extends AuthSession {
  Auth0WebSession(this._config, {String? origin, Auth0Web? auth0})
    : _origin = origin ?? Uri.base.origin,
      _auth0 = auth0 ?? Auth0Web(_config.domain, _config.clientId);

  final Auth0Config _config;
  final String _origin;
  final Auth0Web _auth0;
  UserProfile? _user;

  /// Where Auth0 returns to after sign-in and sign-out: the app's root, which
  /// must be in the Auth0 application's callback, logout and web-origin lists.
  String get _redirectUrl => '$_origin/';

  @override
  bool get isSignedIn => _user != null;

  @override
  String? get displayName => _user?.name ?? _user?.email;

  @override
  String? get subject => _user?.sub;

  @override
  Uri? get pictureUrl => _user?.pictureUrl;

  @override
  Future<void> restore() async {
    try {
      final credentials = await _auth0.onLoad(
        audience: _config.audience,
        scopes: Auth0Config.scopes,
        useRefreshTokens: true,
        cacheLocation: CacheLocation.localStorage,
      );
      _user = credentials?.user;
    } on Object catch (error, stackTrace) {
      // A failed restore (for example an expired callback) is not fatal: the
      // user lands on the landing page signed out.
      _logger.warning('Restoring the Auth0 session failed', error, stackTrace);
      _user = null;
    }
    notifyListeners();
  }

  @override
  Future<void> signIn({bool createAccount = false}) async {
    try {
      await _auth0.loginWithRedirect(
        audience: _config.audience,
        redirectUrl: _redirectUrl,
        scopes: Auth0Config.scopes,
        parameters: createAccount ? const {'screen_hint': 'signup'} : const {},
      );
    } on Object catch (error, stackTrace) {
      _logger.warning('Sign-in failed', error, stackTrace);
      throw const AuthException('Sign-in could not be started.');
    }
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
    await _auth0.logout(returnToUrl: _redirectUrl);
  }

  @override
  Future<String?> accessToken() async {
    if (!isSignedIn) {
      return null;
    }
    try {
      final credentials = await _auth0.credentials(audience: _config.audience);
      return credentials.accessToken;
    } on Object catch (error, stackTrace) {
      _logger.warning('No access token available', error, stackTrace);
      _user = null;
      notifyListeners();
      return null;
    }
  }
}
