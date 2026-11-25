/// Who Auth0 says is signed in, as far as the app needs.
class AuthIdentity {
  const AuthIdentity({this.name, this.email});

  final String? name;
  final String? email;
}

/// The few calls the session makes on Auth0's SPA SDK.
///
/// A thin seam so the session's ordering rules (wait for the SDK, log out
/// before clearing the session) run on the Dart VM in tests; the web
/// implementation is `auth0_web_client.dart`.
abstract class Auth0Client {
  /// Waits until the SDK's script has loaded. The script is `defer`red while
  /// Flutter's own bootstrap is `async`, so the app can start first. False
  /// when it did not arrive within [timeout] (a blocked CDN, say); the
  /// client's own default when null.
  Future<bool> waitUntilReady({Duration? timeout});

  /// Completes a sign-in redirect or restores a stored session; null when
  /// nobody is signed in.
  Future<AuthIdentity?> onLoad();

  /// Leaves the page for Universal Login (its sign-up tab with
  /// [createAccount]).
  Future<void> loginWithRedirect({required bool createAccount});

  /// Ends the session at Auth0 and returns to the app's root.
  Future<void> logout();

  /// A current access token for the API; throws when none can be produced.
  Future<String> accessToken();
}
