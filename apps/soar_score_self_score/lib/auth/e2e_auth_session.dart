import 'auth_session.dart';

/// The bearer token the E2E server (`apps/soar_score_server/tool/
/// e2e_server.dart`, `--profile server`) takes as its seeded pilot account.
const e2ePilotToken = 'e2e-pilot';

/// A sign-in stand-in for the web end-to-end tests: starts signed out, and
/// "signing in" signs in as the E2E server's seeded pilot at once, with no
/// Auth0 round trip. Only a non-release build made with
/// `--dart-define=SOAR_SCORE_E2E=true` uses it (see `auth_session_factory`).
class E2eAuthSession extends AuthSession {
  bool _signedIn = false;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get displayName => _signedIn ? 'Penny Pilot' : null;

  @override
  Future<void> restore() async {}

  @override
  Future<void> signIn({bool createAccount = false, String? returnTo}) async {
    _signedIn = true;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    detailsChecked = false;
    notifyListeners();
  }

  @override
  Future<String?> accessToken() async => _signedIn ? e2ePilotToken : null;
}
