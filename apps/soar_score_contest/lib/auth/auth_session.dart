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

  /// A stable identifier of the signed-in user (the identity provider's
  /// subject), or `null` when signed out or unknown.
  String? get userId => null;

  /// Address of the signed-in user's profile picture (a Gravatar for Auth0
  /// database accounts), or `null` when there is none.
  Uri? get pictureUrl => null;

  /// Why the session ended on its own (for example the refresh token was
  /// revoked), or `null`. Cleared by the next sign-in or sign-out.
  String? get endedReason => null;

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

  /// A current access token for the API, or `null` when signed out or no
  /// token can be produced right now. Whether `null` ends the session is up to
  /// the implementation: it does when the sign-in can no longer be renewed
  /// (see [endedReason]), and does not when renewal only failed for want of a
  /// connection, so the next call tries again.
  Future<String?> accessToken();
}
