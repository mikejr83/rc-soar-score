import 'auth_session.dart';

/// A signed-out session for the landing-page E2E journey.
class E2eSignedOutSession extends AuthSession {
  @override
  bool get isSignedIn => false;

  @override
  String? get displayName => null;

  @override
  Future<void> restore() async {}

  @override
  Future<void> signIn({bool createAccount = false}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> accessToken() async => null;
}
