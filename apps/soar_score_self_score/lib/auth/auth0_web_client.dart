import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:auth0_flutter/auth0_flutter_web.dart';

import 'auth0_client.dart';
import 'auth_config.dart';
import 'renewal_policy.dart';

/// [Auth0Client] over `auth0_flutter`'s web SDK.
class Auth0WebClient implements Auth0Client {
  Auth0WebClient(
    this._config, {
    String? origin,
    this._timeout = const Duration(seconds: 10),
  }) : _origin = origin ?? Uri.base.origin;

  final Auth0Config _config;
  final String _origin;
  final Duration _timeout;
  Auth0Web? _auth0;

  Auth0Web get _sdk => _auth0 ??= Auth0Web(_config.domain, _config.clientId);

  /// Where Auth0 returns to after sign-in and sign-out: the app's root, which
  /// must be in the Auth0 application's callback, logout and web-origin lists.
  String get _redirectUrl => '$_origin/';

  @override
  Future<bool> waitUntilReady({Duration? timeout}) async {
    final end = DateTime.now().add(timeout ?? _timeout);
    // The SDK script defines `window.auth0` when it runs.
    while (!globalContext.has('auth0')) {
      if (DateTime.now().isAfter(end)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return true;
  }

  @override
  Future<AuthIdentity?> onLoad() async {
    final credentials = await _sdk.onLoad(
      audience: _config.audience,
      scopes: Auth0Config.scopes,
      useRefreshTokens: true,
      cacheLocation: CacheLocation.localStorage,
    );
    final user = credentials?.user;
    return user == null
        ? null
        : AuthIdentity(name: user.name, email: user.email);
  }

  @override
  Future<void> loginWithRedirect({required bool createAccount}) =>
      _sdk.loginWithRedirect(
        audience: _config.audience,
        redirectUrl: _redirectUrl,
        scopes: Auth0Config.scopes,
        parameters: createAccount ? const {'screen_hint': 'signup'} : const {},
      );

  @override
  Future<void> logout() => _sdk.logout(returnToUrl: _redirectUrl);

  @override
  Future<String> accessToken() async {
    try {
      return (await _sdk.credentials(audience: _config.audience)).accessToken;
    } on WebException catch (error) {
      if (renewalEndsSession(error.code, error.details)) {
        throw const AuthSessionEndedException();
      }
      rethrow;
    }
  }
}
