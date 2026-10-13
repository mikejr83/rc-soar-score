import 'package:flutter/foundation.dart';

/// Raised when signing in or out fails; [message] is fit to show the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// The signed-in state of the contest app and the source of the access token
/// the remote `ApiClient` sends.
///
/// The web and Windows implementations wrap Auth0's SDK; widgets and the
/// router only see this interface, so tests can pump the app with a fake.
abstract class AuthSession extends ChangeNotifier {
  /// Whether a user is signed in (a stored or just-returned session).
  bool get isSignedIn;

  /// Name or email of the signed-in user, if known.
  String? get displayName;

  /// Restores a stored session, or on web completes a sign-in redirect.
  /// Called once at startup before the first frame.
  Future<void> restore();

  /// Starts sign-in with Auth0's Universal Login. With [createAccount] the
  /// login page opens on its sign-up tab. On web this leaves the page, and the
  /// session is completed by [restore] after the redirect back.
  ///
  /// Throws [AuthException] when sign-in fails or is cancelled.
  Future<void> signIn({bool createAccount = false});

  /// Ends the session here and at Auth0.
  Future<void> signOut();

  /// A current access token for the API, or `null` when signed out or the
  /// session can no longer produce one. A `null` for a signed-in user also
  /// ends the session, so the app asks them to sign in again.
  Future<String?> accessToken();
}
