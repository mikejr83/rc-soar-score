import 'auth_session.dart';

/// An always-signed-in session for the web end-to-end tests.
///
/// The browser build has no local database and no offline mode, so the tests
/// run it against `apps/soar_score_server/tool/e2e_server.dart`, which skips
/// token checks. This session stands in for Auth0 there: it is signed in from
/// the start, sends no token, and signing out is a no-op. Only a non-release
/// build built with `--dart-define=SOAR_SCORE_E2E=true` uses it (see
/// `auth_session_factory_web.dart`).
class E2eSignedInSession extends AuthSession {
  @override
  bool get isSignedIn => true;

  @override
  String? get displayName => 'E2E Director';

  @override
  Future<void> restore() async {}

  @override
  Future<void> signIn({bool createAccount = false}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> accessToken() async => null;
}
