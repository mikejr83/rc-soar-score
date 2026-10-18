import 'package:soar_score_contest/auth/auth_session.dart';

/// `AuthSession` stand-in for widget tests: no Auth0, records calls.
class FakeAuthSession extends AuthSession {
  FakeAuthSession({
    this._signedIn = false,
    this.name,
    this.picture,
    this.subjectId,
  });

  bool _signedIn;
  final String? name;
  final Uri? picture;
  final String? subjectId;

  @override
  String? get subject => _signedIn ? subjectId : null;

  @override
  Uri? get pictureUrl => picture;

  /// Shown on the landing page when the session ended by itself.
  String? reason;

  @override
  String? get endedReason => reason;

  /// Set to make the next `signIn` throw it.
  AuthException? signInError;

  final List<bool> signInCalls = [];
  int signOutCalls = 0;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get displayName => name;

  @override
  Future<void> restore() async {}

  @override
  Future<void> signIn({bool createAccount = false}) async {
    signInCalls.add(createAccount);
    final error = signInError;
    if (error != null) {
      throw error;
    }
    _signedIn = true;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _signedIn = false;
    notifyListeners();
  }

  @override
  Future<String?> accessToken() async => _signedIn ? 'test-token' : null;
}
