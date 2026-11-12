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

  test(
    'the audit id is the service account id, not the sign-in subject',
    () async {
      final session = FakeAuthSession(subjectId: 'auth0|1', signedIn: true);
      final account = AuthUiAccount(session, lookupActor: () async => 'uuid-1');
      addTearDown(account.dispose);

      expect(account.auditActorId, isNull);
      await account.refreshActor();

      expect(account.id, 'user:auth0|1');
      expect(account.auditActorId, 'uuid-1');
      expect((account as UiAccount).auditActorId, 'uuid-1');
    },
  );

  test('the audit id follows sign-in and sign-out and survives a failed '
      'lookup as unknown', () async {
    final session = FakeAuthSession(subjectId: 'auth0|1');
    var fail = false;
    final account = AuthUiAccount(
      session,
      lookupActor: () async {
        if (fail) throw StateError('down');
        return 'uuid-1';
      },
    );
    addTearDown(account.dispose);

    await session.signIn();
    await Future<void>.delayed(Duration.zero);
    expect(account.auditActorId, 'uuid-1');

    await session.signOut();
    expect(account.auditActorId, isNull);

    fail = true;
    await session.signIn();
    await Future<void>.delayed(Duration.zero);
    expect(account.auditActorId, isNull);
  });

  test('an account that is its own audit id answers its id', () {
    expect(const FixedUiAccount('abc').auditActorId, 'abc');
  });
}
