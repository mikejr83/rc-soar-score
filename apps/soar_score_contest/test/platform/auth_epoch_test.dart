import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';

import '../support/gated_auth_session.dart';

void main() {
  late GatedAuthSession auth;
  late AuthEpoch epoch;

  setUp(() {
    auth = GatedAuthSession(signedIn: true);
    epoch = AuthEpoch(auth);
  });
  tearDown(() => epoch.close());

  test(
    'moves on sign-out and on sign-in, not on other notifications',
    () async {
      final first = epoch.value;
      auth.notifyListeners();
      expect(epoch.value, first);

      await auth.signOut();
      expect(epoch.isCurrent(first), isFalse);
      final out = epoch.value;
      expect(epoch.isCurrent(out), isFalse, reason: 'nobody is signed in');

      await auth.signIn();
      expect(epoch.value, isNot(out));
      expect(epoch.isCurrent(epoch.value), isTrue);
    },
  );

  test('an unbound request gets the live token', () async {
    final token = await epoch.boundToken(auth.accessToken)();

    expect(token, 'token-A');
  });

  test('a bound request gets the token of its own sign-in', () async {
    final token = await epoch.runBound(
      epoch.value,
      () => epoch.boundToken(auth.accessToken)(),
    );

    expect(token, 'token-A');
  });

  test('a token looked up across a switch is refused', () async {
    auth.gate = Completer<void>();
    final result = epoch.runBound(
      epoch.value,
      () => epoch.boundToken(auth.accessToken)(),
    );
    await Future<void>.delayed(Duration.zero);

    await auth.switchTo('B');
    auth.gate!.complete();

    await expectLater(result, throwsA(isA<SessionChangedError>()));
  });

  test('the binding follows the operation through its awaits', () async {
    auth.gate = Completer<void>();
    final result = epoch.runBound(epoch.value, () async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      return epoch.boundToken(auth.accessToken)();
    });
    await auth.signOut();
    auth.gate!.complete();

    await expectLater(result, throwsA(isA<SessionChangedError>()));
  });

  test('closing refuses what is still waiting', () async {
    auth.gate = Completer<void>();
    final bound = epoch.value;
    final result = epoch.runBound(
      bound,
      () => epoch.boundToken(auth.accessToken)(),
    );
    await Future<void>.delayed(Duration.zero);

    epoch.close();
    auth.gate!.complete();

    await expectLater(result, throwsA(isA<SessionChangedError>()));
    expect(epoch.isCurrent(bound), isFalse);
  });
}
