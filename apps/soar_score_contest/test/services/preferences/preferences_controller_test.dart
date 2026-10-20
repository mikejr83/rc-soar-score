import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/preferences/preferences_controller.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  preferencesSavingTests();

  test('a supported tag becomes a locale with its region', () {
    expect(
      PreferencesController().localeFor('en-US'),
      const Locale('en', 'US'),
    );
  });

  test('no or an unsupported tag follows the device', () {
    expect(PreferencesController().localeFor(null), isNull);
    expect(PreferencesController().localeFor('xx-XX'), isNull);
  });

  test('load applies the account preference and notifies', () async {
    final controller = PreferencesController(
      loadPreferences: () async => AccountPreferences(preferredLocale: 'en-US'),
    );
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.load();

    expect(controller.locale, const Locale('en', 'US'));
    expect(notified, 1);
  });

  test('a failing load leaves the device locale', () async {
    final controller = PreferencesController(
      loadPreferences: () async => throw StateError('offline'),
    );

    await controller.load();

    expect(controller.locale, isNull);
  });
}

void preferencesSavingTests() {
  group('changing preferences', () {
    test('a zone applies at once and is saved with the locale', () async {
      AccountPreferences? saved;
      final controller = PreferencesController(
        savePreferences: (preferences) async => saved = preferences,
      );
      var notified = 0;
      controller.addListener(() => notified++);

      final result = await controller.setTimeZone('Europe/Rome');

      expect(result, SaveResult.saved);
      expect(controller.timeZone, 'Europe/Rome');
      expect(notified, 1);
      expect(saved?.preferredTimeZone, 'Europe/Rome');
      expect(saved?.preferredLocale, isNull);
    });

    test('a locale keeps the zone already chosen', () async {
      AccountPreferences? saved;
      final controller = PreferencesController(
        loadPreferences: () async =>
            AccountPreferences(preferredTimeZone: 'Asia/Tokyo'),
        savePreferences: (preferences) async => saved = preferences,
      );
      await controller.load();

      await controller.setLocale('en-US');

      expect(saved?.preferredTimeZone, 'Asia/Tokyo');
      expect(saved?.preferredLocale, 'en-US');
    });

    test('clearing the zone saves it as unset', () async {
      AccountPreferences? saved;
      final controller = PreferencesController(
        savePreferences: (preferences) async => saved = preferences,
      );
      await controller.setTimeZone('Europe/Rome');

      await controller.setTimeZone(null);

      expect(controller.timeZone, isNull);
      expect(saved?.preferredTimeZone, isNull);
    });

    test('a failed save still applies the change and says so', () async {
      final controller = PreferencesController(
        savePreferences: (_) async => throw StateError('offline'),
      );

      final result = await controller.setTimeZone('Europe/Rome');

      expect(result, SaveResult.failed);
      expect(controller.timeZone, 'Europe/Rome');
    });

    test('signed out is told apart from a failure', () async {
      final controller = PreferencesController(
        savePreferences: (_) async => throw const SignInRequiredError(),
      );

      expect(await controller.setLocale('en-US'), SaveResult.needsSignIn);
      expect(controller.localeTag, 'en-US');
    });

    test('an unknown zone or locale counts as unset', () async {
      final controller = PreferencesController(
        loadPreferences: () async => AccountPreferences(),
      );

      await controller.setTimeZone('Mars/Olympus');
      await controller.setLocale('xx-XX');

      expect(controller.timeZone, isNull);
      expect(controller.localeTag, isNull);
    });

    test(
      'saves run in the order chosen and each writes both choices',
      () async {
        final started = <AccountPreferences>[];
        final gates = <Completer<void>>[];
        final controller = PreferencesController(
          savePreferences: (preferences) {
            started.add(preferences);
            final gate = Completer<void>();
            gates.add(gate);
            return gate.future;
          },
        );

        final first = controller.setTimeZone('Europe/Rome');
        final second = controller.setLocale('en-US');
        await pumpEventQueue();

        // The second save waits for the first, however long that takes.
        expect(started, hasLength(1));
        gates[0].complete();
        await first;
        await pumpEventQueue();
        expect(started, hasLength(2));
        gates[1].complete();
        await second;

        // The later write carries both choices, so it cannot undo the first.
        expect(started.last.preferredTimeZone, 'Europe/Rome');
        expect(started.last.preferredLocale, 'en-US');
      },
    );
  });

  group('reading the account\'s preferences', () {
    test(
      'a choice made while loading is kept and the other is loaded',
      () async {
        final gate = Completer<AccountPreferences>();
        AccountPreferences? saved;
        final controller = PreferencesController(
          loadPreferences: () => gate.future,
          savePreferences: (preferences) async => saved = preferences,
        );
        final loading = controller.load();

        final change = controller.setLocale('en-US');
        gate.complete(
          AccountPreferences(
            preferredTimeZone: 'Asia/Tokyo',
            preferredLocale: 'en-US',
          ),
        );
        await loading;
        await change;

        // The zone the account already had is neither lost nor cleared.
        expect(controller.timeZone, 'Asia/Tokyo');
        expect(saved?.preferredTimeZone, 'Asia/Tokyo');
        expect(saved?.preferredLocale, 'en-US');
      },
    );

    test('a late answer does not undo a newer choice', () async {
      final gate = Completer<AccountPreferences>();
      final controller = PreferencesController(
        loadPreferences: () => gate.future,
        savePreferences: (_) async {},
      );
      final loading = controller.load();

      final change = controller.setTimeZone('Europe/Rome');
      gate.complete(AccountPreferences(preferredTimeZone: 'Asia/Tokyo'));
      await loading;
      await change;

      expect(controller.timeZone, 'Europe/Rome');
    });

    test('the account changing behind the app is read again', () async {
      var onAccount = AccountPreferences();
      final changes = StreamController<void>.broadcast();
      final controller = PreferencesController(
        loadPreferences: () async => onAccount,
        changes: changes.stream,
      );
      await controller.load();
      expect(controller.timeZone, isNull);

      // The sign-in finishes merging the account's choices later.
      onAccount = AccountPreferences(preferredTimeZone: 'Asia/Tokyo');
      changes.add(null);
      await pumpEventQueue();

      expect(controller.timeZone, 'Asia/Tokyo');
    });

    test('a re-read waits for a save in flight', () async {
      var onAccount = AccountPreferences();
      final changes = StreamController<void>.broadcast();
      final gate = Completer<void>();
      final controller = PreferencesController(
        loadPreferences: () async => onAccount,
        savePreferences: (_) => gate.future,
        changes: changes.stream,
      );
      await controller.load();

      final change = controller.setTimeZone('Europe/Rome');
      changes.add(null);
      await pumpEventQueue();
      gate.complete();
      await change;

      expect(controller.timeZone, 'Europe/Rome');
    });

    test(
      'a re-read during the first load keeps a choice made meanwhile',
      () async {
        final firstRead = Completer<AccountPreferences>();
        final changes = StreamController<void>.broadcast();
        var reads = 0;
        final controller = PreferencesController(
          loadPreferences: () {
            reads++;
            return reads == 1
                ? firstRead.future
                : Future.value(
                    AccountPreferences(preferredTimeZone: 'Asia/Tokyo'),
                  );
          },
          savePreferences: (_) async {},
          changes: changes.stream,
        );
        final loading = controller.load();

        final change = controller.setTimeZone('Europe/Rome');
        changes.add(null);
        await pumpEventQueue();
        firstRead.complete(AccountPreferences(preferredTimeZone: 'Asia/Tokyo'));
        await loading;
        await change;

        expect(controller.timeZone, 'Europe/Rome');
      },
    );

    test('a re-read that began before a save finished is dropped', () async {
      var onAccount = AccountPreferences();
      final slowRead = Completer<AccountPreferences>();
      final changes = StreamController<void>.broadcast();
      var reads = 0;
      final controller = PreferencesController(
        loadPreferences: () {
          reads++;
          return reads == 2 ? slowRead.future : Future.value(onAccount);
        },
        savePreferences: (saved) async => onAccount = saved,
        changes: changes.stream,
      );
      await controller.load();

      final change = controller.setTimeZone('Europe/Rome');
      changes.add(null);
      await pumpEventQueue();
      await change;
      // The answer was read before the save, so it still shows no zone.
      slowRead.complete(AccountPreferences());
      await pumpEventQueue();

      expect(controller.timeZone, 'Europe/Rome');
    });
  });
}
