import 'package:logging/logging.dart';

import 'auth0_client.dart';
import 'auth_session.dart';

final _logger = Logger('Auth0Session');

/// Sign-in through Auth0's Universal Login (redirect flow with PKCE), over an
/// [Auth0Client].
///
/// `signIn` leaves the page; Auth0 returns to the app's origin with a code,
/// and [restore] (run before the first frame) exchanges it. Order matters:
///
/// - [restore] waits for the SDK script first. If it never arrives, the
///   pending callback is still unprocessed, so [signIn] runs the restore
///   again before it starts a new sign-in (and a callback that turns out to be
///   good signs the pilot in without another redirect).
/// - [signOut] clears the session only after Auth0 has logged out, so a
///   failure leaves the pilot signed in with the sign-out still on offer.
class Auth0Session extends AuthSession {
  Auth0Session(this._client);

  final Auth0Client _client;
  AuthIdentity? _user;
  bool _restored = false;

  @override
  bool get isSignedIn => _user != null;

  @override
  String? get displayName => _user?.name ?? _user?.email;

  @override
  Future<void> restore() async {
    try {
      if (!await _client.waitUntilReady()) {
        _logger.warning('The Auth0 SDK did not load; session not restored');
        return;
      }
      _user = await _client.onLoad();
      _restored = true;
    } on Object catch (error, stackTrace) {
      // A failed restore (an expired callback, say) is not fatal: the pilot
      // lands on the landing page signed out. It was attempted, so it is not
      // retried.
      _logger.warning('Restoring the Auth0 session failed', error, stackTrace);
      _user = null;
      _restored = true;
    } finally {
      notifyListeners();
    }
  }

  @override
  Future<void> signIn({bool createAccount = false}) async {
    if (!_restored) {
      await restore();
      if (isSignedIn) return;
      if (!_restored) {
        throw const AuthException('Sign-in could not be started.');
      }
    }
    try {
      await _client.loginWithRedirect(createAccount: createAccount);
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
