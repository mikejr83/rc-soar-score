import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

class _UnreachableRepository extends SampleSelfScoreRepository {
  _UnreachableRepository();

  bool reachable = false;

  @override
  Future<GuestSession> acceptInvitation(String credential) async {
    if (!reachable) throw const SelfScoreLoadException('offline');
    return super.acceptInvitation(credential);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required GuestSessionStore store,
  SelfScoreRepository repository = const SampleSelfScoreRepository(),
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GuestSessionScope(
      store: store,
      child: SelfScoreScope(
        repository: repository,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a good link asks the pilot to continue as a guest', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore();
    await _pump(tester, store: store);
    router.go(invitationPath('sample-link'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Jane Smith'), findsOneWidget);
    expect(find.textContaining('Spring Open'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    // Sign in and Create account are shown but not connected yet.
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Sign in'),
          )
          .onPressed,
      isNull,
    );
    expect(store.read(), isNull, reason: 'nothing is kept before accepting');
  });

  testWidgets('continuing stores the session and drops the credential', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore();
    await _pump(tester, store: store);
    router.go(invitationPath('sample-link'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(store.read()?.pilotId, '12');
    expect(store.read()?.token, 'sample-token');
    expect(find.text('Next to score'), findsOneWidget);
    final location = router.routeInformationProvider.value.uri.toString();
    expect(location, '/contests/spring-open/pilots/12');
    expect(location, isNot(contains('sample-link')));
    // The invitation is not left under the pilot overview in the history.
    final stack = router.routerDelegate.currentConfiguration.matches.map(
      (match) => match.matchedLocation,
    );
    expect(stack.any((path) => path.contains('invitations')), isFalse);
  });

  testWidgets('unknown, expired and replaced links share one message', (
    tester,
  ) async {
    await _pump(tester, store: MemoryGuestSessionStore());
    router.go(invitationPath('nope'));
    await tester.pumpAndSettle();

    expect(find.text('This link does not work'), findsOneWidget);
    expect(find.textContaining('Ask your contest director'), findsOneWidget);
    expect(find.text('Continue as guest'), findsNothing);
  });

  testWidgets('an unreachable server offers Retry, not the invalid message', (
    tester,
  ) async {
    final repository = _UnreachableRepository();
    await _pump(
      tester,
      store: MemoryGuestSessionStore(),
      repository: repository,
    );
    router.go(invitationPath('sample-link'));
    await tester.pumpAndSettle();

    expect(find.text('This link does not work'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    repository.reachable = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('a guest returning to the contest lands on the pilot overview', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore()
      ..write(
        const GuestSession(
          contestId: 'spring-open',
          contestName: 'Spring Open',
          pilotId: '12',
          pilotName: 'Jane Smith',
          token: 'sample-token',
        ),
      );
    await _pump(tester, store: store);
    router.go('/contests/spring-open');
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/contests/spring-open/pilots/12',
    );
    expect(find.text('Next to score'), findsOneWidget);
  });

  group('StringSlotGuestSessionStore', () {
    test('keeps and clears a session', () {
      final slot = _MapSlot();
      final store = StringSlotGuestSessionStore(slot);
      const session = GuestSession(
        contestId: 'c',
        contestName: 'Contest',
        pilotId: 'p',
        pilotName: 'Pat',
        token: 't',
      );
      store.write(session);
      expect(store.read()?.token, 't');
      expect(store.read()?.pilotName, 'Pat');
      store.clear();
      expect(store.read(), isNull);
    });

    test('a damaged slot reads as no session', () {
      final slot = _MapSlot()..value = '{not json';
      expect(StringSlotGuestSessionStore(slot).read(), isNull);
    });

    test('blocked storage does not throw', () {
      final store = StringSlotGuestSessionStore(_BlockedSlot());
      expect(store.read, returnsNormally);
      expect(
        () => store.write(
          const GuestSession(
            contestId: 'c',
            contestName: 'C',
            pilotId: 'p',
            pilotName: 'P',
            token: 't',
          ),
        ),
        returnsNormally,
      );
      expect(store.clear, returnsNormally);
    });
  });
}

class _MapSlot implements StringSlot {
  String? value;

  @override
  String? read() => value;

  @override
  void write(String value) => this.value = value;

  @override
  void clear() => value = null;
}

class _BlockedSlot implements StringSlot {
  @override
  String? read() => throw StateError('blocked');

  @override
  void write(String value) => throw StateError('blocked');

  @override
  void clear() => throw StateError('blocked');
}
