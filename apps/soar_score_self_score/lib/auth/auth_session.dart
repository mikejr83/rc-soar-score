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

  /// Whether the first [restore] is still running (the SDK is loading, or a
  /// sign-in redirect is being completed). The pages show guest routes at
  /// once and keep the sign-in controls off meanwhile.
  bool get isInitializing => false;

  /// Whether a pilot is signed in (a stored or just-returned session).
  bool get isSignedIn;

  /// Name or email of the signed-in pilot, if known.
  String? get displayName;

  /// Restores a stored session, or completes a sign-in redirect. Started right
  /// after the first frame is requested, not awaited by it: guest routes do
  /// not depend on Auth0. Calls that overlap share one run.
  Future<void> restore();

  /// Starts sign-in with Auth0's Universal Login; with [createAccount] the
  /// login page opens on its sign-up tab. On the web this leaves the page, and
  /// [restore] completes the session after the redirect back.
  ///
  /// Throws [AuthException] when sign-in cannot be started.
  Future<void> signIn({bool createAccount = false});

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
  Future<void> signIn({bool createAccount = false}) async =>
      throw const AuthException('Signing in is not available.');

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> accessToken() async => null;
}
