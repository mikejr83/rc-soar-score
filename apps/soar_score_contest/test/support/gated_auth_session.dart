import 'dart:async';

import 'fake_auth_session.dart';

/// A [FakeAuthSession] whose access-token lookup can be held, and whose
/// token names the signed-in user at the moment the lookup finishes, so a
/// test can see which identity a request carried.
class GatedAuthSession extends FakeAuthSession {
  GatedAuthSession({super.signedIn, this.user = 'A'});

  /// Who is signed in; a token is `token-<user>`.
  String user;

  /// While set, [accessToken] waits for it.
  Completer<void>? gate;

  /// Signs out and signs in as [next] without any await in between.
  Future<void> switchTo(String next) async {
    await signOut();
    user = next;
    await signIn();
  }

  @override
  Future<String?> accessToken() async {
    final held = gate;
    if (held != null) await held.future;
    return isSignedIn ? 'token-$user' : null;
  }
}
