import 'package:flutter/foundation.dart';

/// Raised when signing in or out fails; [message] is fit to show the pilot.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// The pilot's signed-in state and the source of the access token the
/// account routes of the API take.
///
/// The web implementation wraps Auth0's SPA SDK. Pages only see this
/// interface, so tests pump the app with a fake. The guest session of an
/// invitation link is a separate thing (`session/`): signing in does not end
/// it, and it does not sign anyone in.
abstract class AuthSession extends ChangeNotifier {
  /// Whether signing in is possible in this build. False in a build with no
  /// identity provider (tests that do not set one up); the landing page then
  /// leaves its buttons off.
  bool get isAvailable => true;

  /// Whether a pilot is signed in (a stored or just-returned session).
  bool get isSignedIn;

  /// Name or email of the signed-in pilot, if known.
  String? get displayName;

  /// Restores a stored session, or completes a sign-in redirect. Called once
  /// before the first frame.
  Future<void> restore();

  /// Starts sign-in with Auth0's Universal Login; with [createAccount] the
  /// login page opens on its sign-up tab. On the web this leaves the page, and
  /// [restore] completes the session after the redirect back.
  ///
  /// With [returnTo], an address inside the app, [takeReturnTo] hands it back
  /// after the redirect so the pilot lands where they were (an invitation
  /// link, say).
  ///
  /// Throws [AuthException] when sign-in cannot be started.
  Future<void> signIn({bool createAccount = false, String? returnTo});

  /// The address passed to [signIn] as `returnTo`, once, after a sign-in
  /// redirect completed; null otherwise. It is always a path inside the app.
  String? takeReturnTo() => null;

  /// Ends the session here and at Auth0.
  Future<void> signOut();

  /// A current access token for the account routes, or null when signed out
  /// or none can be produced right now.
  Future<String?> accessToken();
}

/// The session of a build with no sign-in: signed out, nothing to start.
class UnavailableAuthSession extends AuthSession {
  @override
  bool get isAvailable => false;

  @override
  bool get isSignedIn => false;

  @override
  String? get displayName => null;

  @override
  Future<void> restore() async {}

  @override
  Future<void> signIn({bool createAccount = false, String? returnTo}) async =>
      throw const AuthException('Signing in is not available.');

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> accessToken() async => null;
}
