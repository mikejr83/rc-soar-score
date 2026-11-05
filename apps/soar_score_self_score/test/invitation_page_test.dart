import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/models/pilot_overview.dart';
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
  _securityTests();
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
        GuestSession(
          contestId: 'spring-open',
          contestName: 'Spring Open',
          pilotId: '12',
          pilotName: 'Jane Smith',
          token: 'sample-token',
          expiresAt: DateTime.utc(2099),
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
      final session = GuestSession(
        contestId: 'c',
        contestName: 'Contest',
        pilotId: 'p',
        pilotName: 'Pat',
        token: 't',
        expiresAt: DateTime.utc(2099),
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
          GuestSession(
            contestId: 'c',
            contestName: 'C',
            pilotId: 'p',
            pilotName: 'P',
            token: 't',
            expiresAt: DateTime.utc(2099),
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

class _HelperLinkRepository extends SampleSelfScoreRepository {
  _HelperLinkRepository();

  @override
  Future<GuestSession> acceptInvitation(String credential) async {
    final session = await super.acceptInvitation(credential);
    return GuestSession(
      contestId: session.contestId,
      contestName: session.contestName,
      pilotId: session.pilotId,
      pilotName: session.pilotName,
      token: session.token,
      role: 'helper',
      expiresAt: session.expiresAt,
    );
  }
}

class _SessionEndedRepository extends SampleSelfScoreRepository {
  const _SessionEndedRepository();

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) async =>
      throw const SessionEndedException();
}

void _securityTests() {
  final session = GuestSession(
    contestId: 'spring-open',
    contestName: 'Spring Open',
    pilotId: '12',
    pilotName: 'Jane Smith',
    token: 'sample-token',
    expiresAt: DateTime.utc(2099),
  );

  testWidgets('a hand-edited pilot id returns to the guest\'s own pilot', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore()..write(session);
    await _pump(tester, store: store);
    router.go('/contests/spring-open/pilots/3');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/contests/spring-open/pilots/12',
    );
  });

  testWidgets('another contest\'s pages lead back to the guest\'s contest', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore()..write(session);
    await _pump(tester, store: store);
    router.go('/contests/other/pilots/12');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/contests/spring-open/pilots/12',
    );
  });

  testWidgets('an ended session is dropped when a page finds out', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore()..write(session);
    await _pump(
      tester,
      store: store,
      repository: const _SessionEndedRepository(),
    );
    router.go('/contests/spring-open/pilots/12');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Open your invitation link again'),
      findsOneWidget,
    );
    expect(store.read(), isNull);

    // Retrying cannot help, so the page offers the way back instead.
    expect(find.text('Retry'), findsNothing);
    await tester.tap(find.text('Back to start'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('a link for another role is not treated as a pilot', (
    tester,
  ) async {
    await _pump(
      tester,
      store: MemoryGuestSessionStore(),
      repository: _HelperLinkRepository(),
    );
    router.go(invitationPath('sample-link'));
    await tester.pumpAndSettle();

    expect(find.text('This link is not for scoring yet'), findsOneWidget);
    expect(find.text('Continue as guest'), findsNothing);
  });

  testWidgets('a stored helper session never routes to a pilot page', (
    tester,
  ) async {
    final store = MemoryGuestSessionStore()
      ..write(
        GuestSession(
          contestId: 'spring-open',
          contestName: 'Spring Open',
          pilotId: 'helper-1',
          pilotName: 'Helper',
          token: 't',
          role: 'helper',
          expiresAt: DateTime.utc(2099),
        ),
      );
    await _pump(tester, store: store);
    router.go('/contests/spring-open/pilots/helper-1');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/contests/spring-open/team',
    );
  });

  test('a stored session without a readable expiry is not used', () {
    for (final json in [
      '{"contestId":"c","contestName":"C","pilotId":"p","pilotName":"P",'
          '"token":"t"}',
      '{"contestId":"c","contestName":"C","pilotId":"p","pilotName":"P",'
          '"token":"t","expiresAt":"soon"}',
    ]) {
      final slot = _MapSlot()..value = json;
      expect(StringSlotGuestSessionStore(slot).read(), isNull);
    }
  });

  test('credentials with reserved characters stay one path segment', () {
    expect(invitationPath('a/b?c#d e'), '/invitations/a%2Fb%3Fc%23d%20e');
  });

  test('an expired session reads as no session', () {
    final slot = _MapSlot();
    var now = DateTime.utc(2026, 11, 8);
    final store = StringSlotGuestSessionStore(slot, now: () => now)
      ..write(
        GuestSession(
          contestId: 'c',
          contestName: 'C',
          pilotId: 'p',
          pilotName: 'P',
          token: 't',
          expiresAt: DateTime.utc(2026, 11, 9),
        ),
      );
    expect(store.read()?.expiresAt, DateTime.utc(2026, 11, 9));
    now = DateTime.utc(2026, 11, 9);
    expect(store.read(), isNull);
    expect(slot.value, isNull, reason: 'the stale session is removed');
  });
}
