import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/native_preferences.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/fake_auth_session.dart';
import '../support/fake_local_account.dart';

void main() {
  final rome = core.AccountPreferences(preferredTimeZone: 'Europe/Rome');
  late FakeAuthSession auth;
  late FakeLocalAccount local;
  late List<core.AccountPreferences> uploads;
  late Future<void> Function()? uploadGate;
  late Object? uploadError;
  late NativePreferences preferences;

  NativePreferences build({Duration timeout = const Duration(seconds: 10)}) =>
      NativePreferences(
        epoch: AuthEpoch(auth),
        local: local,
        put: (value) async {
          await uploadGate?.call();
          final error = uploadError;
          if (error != null) throw error;
          uploads.add(value);
          return value;
        },
        uploadTimeout: timeout,
      );

  setUp(() {
    auth = FakeAuthSession();
    local = FakeLocalAccount(core.Id.create());
    uploads = [];
    uploadGate = null;
    uploadError = null;
    preferences = build();
  });
  tearDown(() => preferences.close());

  test('signed out, the choice is kept on this installation only', () async {
    await preferences.save(rome);

    expect(local.storedPreferences, rome);
    expect(uploads, isEmpty);
    expect(await preferences.load(), rome);
  });

  test(
    'signed in, the choice goes to the account and this installation',
    () async {
      auth = FakeAuthSession(signedIn: true);
      preferences = build();

      await preferences.save(rome);

      expect(uploads, [rome]);
      expect(local.storedPreferences, rome);
    },
  );

  test(
    'signed in, a failed upload is a failed save and keeps nothing',
    () async {
      auth = FakeAuthSession(signedIn: true);
      preferences = build();
      uploadError = StateError('unreachable');

      await expectLater(preferences.save(rome), throwsStateError);

      expect(local.storedPreferences.isEmpty, isTrue);
    },
  );

  test('signed in, a stalled service counts as a failed save', () async {
    auth = FakeAuthSession(signedIn: true);
    preferences = build(timeout: const Duration(milliseconds: 20));
    uploadGate = () => Completer<void>().future;

    await expectLater(preferences.save(rome), throwsA(isA<TimeoutException>()));

    expect(local.storedPreferences.isEmpty, isTrue);
  });

  test('a sign-out during the upload keeps it off this installation', () async {
    auth = FakeAuthSession(signedIn: true);
    preferences = build();
    final gate = Completer<void>();
    uploadGate = () => gate.future;

    final saving = preferences.save(rome);
    await pumpEventQueue();
    await auth.signOut();
    gate.complete();

    await expectLater(saving, throwsA(isA<Exception>()));
    expect(local.storedPreferences.isEmpty, isTrue);
  });

  test('a change in the installation\'s copy is announced', () async {
    final seen = <void>[];
    final listener = preferences.changes.listen(seen.add);

    preferences.changed();
    await pumpEventQueue();

    expect(seen, hasLength(1));
    await listener.cancel();
  });
}
