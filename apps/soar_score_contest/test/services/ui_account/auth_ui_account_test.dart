import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/ui_account/auth_ui_account.dart';
import 'package:soar_score_contest/services/ui_account/ui_account.dart';

import '../../support/fake_auth_session.dart';

void main() {
  test('is the Local account while signed out', () {
    final account = AuthUiAccount(FakeAuthSession(subjectId: 'auth0|1'));
    addTearDown(account.dispose);

    expect(account.id, localUiAccountId);
  });

  test('is the signed-in user, and follows sign-in and sign-out', () async {
    final session = FakeAuthSession(subjectId: 'auth0|1');
    final account = AuthUiAccount(session);
    addTearDown(account.dispose);
    var changes = 0;
    account.addListener(() => changes++);

    await session.signIn();
    expect(account.id, 'user:auth0|1');
    expect(changes, 1);

    await session.signOut();
    expect(account.id, localUiAccountId);
    expect(changes, 2);
  });

  test('stays the Local account when the session has no subject', () {
    final account = AuthUiAccount(FakeAuthSession(signedIn: true));
    addTearDown(account.dispose);

    expect(account.id, localUiAccountId);
  });
}
