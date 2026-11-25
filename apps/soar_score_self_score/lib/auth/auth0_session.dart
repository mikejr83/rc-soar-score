import 'dart:async';

import 'package:logging/logging.dart';

import 'auth0_client.dart';
import 'auth_session.dart';

final _logger = Logger('Auth0Session');

/// Sign-in through Auth0's Universal Login (redirect flow with PKCE), over an
/// [Auth0Client].
///
/// `signIn` leaves the page; Auth0 returns to the app's origin with a code,
/// and [restore] (started right after the first frame) exchanges it. Order
/// matters:
///
/// - [restore] waits for the SDK script first. If it is late, the session
///   keeps watching for it and restores when it lands; if it never arrives,
///   the pending callback is still unprocessed, so [signIn] runs the restore
///   again before it starts a new sign-in (and a callback that turns out to be
///   good signs the pilot in without another redirect).
/// - Overlapping calls share one run: a second [restore] or [signIn] while one
///   is in flight returns the first's result. The SDK takes a callback once;
///   a second pass would find its stored transaction gone and start a new
///   redirect over a valid code exchange.
/// - [signOut] clears the session only after Auth0 has logged out, so a
///   failure leaves the pilot signed in with the sign-out still on offer.
class Auth0Session extends AuthSession {
  Auth0Session(this._client);

  final Auth0Client _client;
  AuthIdentity? _user;
  bool _restored = false;
  bool _initializing = true;
  Future<void>? _restoring;
  Future<void>? _signingIn;
  String? _returnTo;
  bool _watchingForSdk = false;

  /// How long a late SDK script is still waited for after the first timeout.
  static const _lateSdkWindow = Duration(minutes: 2);

  @override
  bool get isInitializing => _initializing;

  @override
  bool get isSignedIn => _user != null;

  @override
  String? get displayName => _user?.name ?? _user?.email;

  @override
  Future<void> restore() =>
      _restoring ??= _restore().whenComplete(() => _restoring = null);

  Future<void> _restore() async {
    try {
      if (!await _client.waitUntilReady()) {
        _logger.warning('The Auth0 SDK did not load; session not restored');
        unawaited(_restoreWhenSdkArrives());
        return;
      }
      final identity = await _client.onLoad();
      _user = identity;
      _returnTo = identity?.returnTo;
      _restored = true;
    } on Object catch (error, stackTrace) {
      // A failed restore (an expired callback, say) is not fatal: the pilot
      // lands on the landing page signed out. It was attempted, so it is not
      // retried.
      _logger.warning('Restoring the Auth0 session failed', error, stackTrace);
      _user = null;
      _restored = true;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  /// A slow network can deliver the SDK after the first wait gave up, with a
  /// sign-in callback still in the URL. Watch for it a while longer and run
  /// the shared restore (once) when it lands.
  Future<void> _restoreWhenSdkArrives() async {
    if (_watchingForSdk) return;
    _watchingForSdk = true;
    try {
      if (await _client.waitUntilReady(timeout: _lateSdkWindow) && !_restored) {
        await restore();
      }
    } on Object catch (error, stackTrace) {
      _logger.warning('Late Auth0 restore failed', error, stackTrace);
    } finally {
      _watchingForSdk = false;
    }
  }

  @override
  String? takeReturnTo() {
    final path = _returnTo;
    _returnTo = null;
    return path;
  }

  @override
  Future<void> signIn({bool createAccount = false, String? returnTo}) =>
      _signingIn ??= _signIn(
        createAccount: createAccount,
        returnTo: returnTo,
      ).whenComplete(() => _signingIn = null);

  Future<void> _signIn({required bool createAccount, String? returnTo}) async {
    if (!_restored) {
      await restore();
      if (isSignedIn) return;
      if (!_restored) {
        throw const AuthException('Sign-in could not be started.');
      }
    }
    try {
      await _client.loginWithRedirect(
        createAccount: createAccount,
        returnTo: returnTo,
      );
    } on Object catch (error, stackTrace) {
      _logger.warning('Sign-in failed', error, stackTrace);
      throw const AuthException('Sign-in could not be started.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.logout();
    } on Object catch (error, stackTrace) {
      _logger.warning('Sign-out failed', error, stackTrace);
      throw const AuthException('Sign-out could not be completed.');
    }
    _user = null;
    notifyListeners();
  }

  @override
  Future<String?> accessToken() async {
    if (!isSignedIn) return null;
    try {
      return await _client.accessToken();
    } on Object catch (error, stackTrace) {
      _logger.warning('No access token available', error, stackTrace);
      _user = null;
      notifyListeners();
      return null;
    }
  }
}
