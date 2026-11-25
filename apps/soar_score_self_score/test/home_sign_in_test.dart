import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/api_client_provider.dart';
import 'package:soar_score_self_score/auth/auth_scope.dart';
import 'package:soar_score_self_score/auth/auth_session.dart';
import 'package:soar_score_self_score/auth/e2e_auth_session.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/pages/contests_page.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/pages/home_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/contest_open_gate.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

/// A session that records what the landing page asks of it.
class _GatedOpenRepository extends SampleSelfScoreRepository {
  _GatedOpenRepository(this.gate);

  final Future<GuestSession> gate;

  @override
  Future<ContestsView> contests() async => ContestsView(
    contests: [
      ContestSummary(
        participationId: 'p-b',
        contestId: 'c-b',
        name: 'Spring Open',
        startDate: DateTime.utc(2026, 10, 10),
        endDate: DateTime.utc(2026, 10, 10),
        phase: ContestPhase.invited,
      ),
    ],
  );

  @override
  Future<GuestSession> openContest(String participationId) => gate;
}

class _FakeAuth extends E2eAuthSession {
  bool initializing = false;
  Completer<void>? signInGate;

  @override
  bool get isInitializing => initializing;

  final calls = <String>[];
  bool failNext = false;
  bool failSignOut = false;
  Completer<void>? signOutGate;

  @override
  Future<void> signOut() async {
    calls.add('sign-out');
    await signOutGate?.future;
    if (failSignOut) throw StateError('logout failed');
    await super.signOut();
  }

  @override
  Future<void> signIn({bool createAccount = false}) async {
    calls.add(createAccount ? 'sign-up' : 'sign-in');
    await signInGate?.future;
    if (failNext) throw const AuthException('no');
    await super.signIn(createAccount: createAccount);
  }
}

Future<void> _pump(
  WidgetTester tester,
  AuthSession auth, {
  GuestSessionStore? sessions,
  ApiClient? client,
  ContestOpenGate? gate,
  void Function(ContestOpenGate gate)? beforePump,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget app = MaterialApp.router(
    localizationsDelegates: appLocalizationDelegates,
    routerConfig: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: contestsPath,
          builder: (context, state) =>
              const Scaffold(body: Text('Contests page')),
        ),
      ],
    ),
  );
  if (client != null) {
    app = ApiClientInherited(client: client, child: app);
  }
  if (sessions != null) {
    app = GuestSessionScope(store: sessions, child: app);
  }
  if (gate != null) {
    beforePump?.call(gate);
    app = ContestOpenScope(gate: gate, child: app);
  }
  await tester.pumpWidget(AuthScope(session: auth, child: app));
}

void main() {
  testWidgets('signed out, Sign in and Sign up start the right flow', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await _pump(tester, auth);

    expect(find.textContaining('coming in a future release'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(auth.calls, ['sign-in']);
  });

  testWidgets('Sign up opens the sign-up page', (tester) async {
    final auth = _FakeAuth();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign up'));
    await tester.pump();
    expect(auth.calls, ['sign-up']);
  });

  testWidgets('a sign-in that cannot start says so and stays signed out', (
    tester,
  ) async {
    final auth = _FakeAuth()..failNext = true;
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Sign-in could not be started. Try again.'), findsOne);
    expect(auth.isSignedIn, isFalse);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('signed in, the page shows the pilot and the way on', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await auth.signIn();
    await _pump(tester, auth);

    expect(find.text('Signed in as Penny Pilot'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'My contests'));
    await tester.pumpAndSettle();
    expect(find.text('Contests page'), findsOneWidget);
  });

  testWidgets('Sign out returns to the signed-out page', (tester) async {
    final auth = _FakeAuth();
    await auth.signIn();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  group('Sign out with a contest session from the list', () {
    final stored = GuestSession(
      contestId: 'c',
      contestName: 'C',
      pilotId: 'p',
      pilotName: 'P',
      expiresAt: DateTime.utc(2099),
    );

    testWidgets('ends it at the server and on the device, then signs out', (
      tester,
    ) async {
      final auth = _FakeAuth();
      await auth.signIn();
      final sessions = MemoryGuestSessionStore()..write(stored);
      final calls = <String>[];
      await _pump(
        tester,
        auth,
        sessions: sessions,
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost:8080'),
          httpClient: MockClient((request) async {
            calls.add('${request.method} ${request.url.path}');
            return http.Response('', 204);
          }),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(calls, ['POST /api/v1/self-scoring/session/end']);
      expect(sessions.read(), isNull);
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets('is asked to end it even with no stored record', (
      tester,
    ) async {
      final auth = _FakeAuth();
      await auth.signIn();
      final calls = <String>[];
      await _pump(
        tester,
        auth,
        sessions: MemoryGuestSessionStore(),
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost:8080'),
          httpClient: MockClient((request) async {
            calls.add('${request.method} ${request.url.path}');
            return http.Response('', 204);
          }),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(calls, ['POST /api/v1/self-scoring/session/end']);
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets('waits for a contest still opening before clearing it', (
      tester,
    ) async {
      final auth = _FakeAuth();
      await auth.signIn();
      final events = <String>[];
      final answer = Completer<String>();
      await _pump(
        tester,
        auth,
        sessions: MemoryGuestSessionStore(),
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost:8080'),
          httpClient: MockClient((request) async {
            events.add('end');
            return http.Response('', 204);
          }),
        ),
        gate: ContestOpenGate(),
        beforePump: (gate) {
          // An open sent from My Contests that has not answered yet.
          unawaited(
            gate.run<String>(() async {
              final text = await answer.future;
              events.add('open answered: $text');
              return text;
            }),
          );
        },
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(events, isEmpty, reason: 'nothing is cleared while it is open');
      expect(auth.isSignedIn, isTrue);

      answer.complete('set the cookie');
      await tester.pumpAndSettle();

      expect(events, ['open answered: set the cookie', 'end']);
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets(
      'an open finishing during sign-out leaves the pilot on Home with the failure',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = _FakeAuth();
        await auth.signIn();
        final sessions = MemoryGuestSessionStore();
        final gate = ContestOpenGate();
        final answer = Completer<GuestSession>();
        final repository = _GatedOpenRepository(answer.future);
        final endCalls = <String>[];
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
            GoRoute(
              path: contestsPath,
              builder: (context, state) => const ContestsPage(),
            ),
            GoRoute(
              path: '/contests/:contestId/pilots/:pilotId',
              builder: (context, state) =>
                  const Scaffold(body: Text('Pilot page')),
            ),
          ],
        );
        await tester.pumpWidget(
          AuthScope(
            session: auth,
            child: ApiClientInherited(
              client: ApiClient(
                baseUrl: Uri.parse('http://localhost:8080'),
                // The end call fails: the failure has to stay visible on Home.
                httpClient: MockClient((request) async {
                  endCalls.add(request.url.path);
                  return http.Response('', 500);
                }),
              ),
              child: GuestSessionScope(
                store: sessions,
                child: ContestOpenScope(
                  gate: gate,
                  child: SelfScoreScope(
                    repository: repository,
                    child: MaterialApp.router(
                      localizationsDelegates: appLocalizationDelegates,
                      routerConfig: router,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // My contests, and start opening a contest.
        await tester.tap(find.widgetWithText(FilledButton, 'My contests'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spring Open'));
        await tester.pump();

        // Back to Home, and sign out while the open is still out.
        router.go('/');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
        await tester.pump();
        answer.complete(
          GuestSession(
            contestId: 'c',
            contestName: 'n',
            pilotId: 'p',
            pilotName: 'x',
            expiresAt: DateTime.utc(2099),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pilot page'), findsNothing);
        expect(sessions.read(), isNull, reason: 'the late result is dropped');
        expect(
          find.text('Sign-out could not be completed. Try again.'),
          findsOneWidget,
        );
        expect(auth.isSignedIn, isTrue);
        expect(endCalls, [
          '/api/v1/self-scoring/session/end',
        ], reason: 'only the sign-out ends the session, not the late open');
      },
    );

    testWidgets(
      'a contest open finishing while My Contests stays mounted is dropped',
      (tester) async {
        final auth = _FakeAuth();
        await auth.signIn();
        final sessions = MemoryGuestSessionStore();
        final gate = ContestOpenGate();
        final answer = Completer<GuestSession>();
        final endCalls = <String>[];
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ContestsPage(),
            ),
            GoRoute(
              path: '/contests/:contestId/pilots/:pilotId',
              builder: (context, state) =>
                  const Scaffold(body: Text('Pilot page')),
            ),
          ],
        );
        await tester.pumpWidget(
          AuthScope(
            session: auth,
            child: ApiClientInherited(
              client: ApiClient(
                baseUrl: Uri.parse('http://localhost:8080'),
                httpClient: MockClient((request) async {
                  endCalls.add(request.url.path);
                  return http.Response('', 204);
                }),
              ),
              child: GuestSessionScope(
                store: sessions,
                child: ContestOpenScope(
                  gate: gate,
                  child: SelfScoreScope(
                    repository: _GatedOpenRepository(answer.future),
                    child: MaterialApp.router(
                      localizationsDelegates: appLocalizationDelegates,
                      routerConfig: router,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spring Open'));
        await tester.pump();

        // A sign-out from elsewhere in the app, while the page is still there.
        final signOut = gate.signOut(() async {
          endCalls.add('/sign-out-teardown');
        });
        await tester.pump();
        answer.complete(
          GuestSession(
            contestId: 'c',
            contestName: 'n',
            pilotId: 'p',
            pilotName: 'x',
            expiresAt: DateTime.utc(2099),
          ),
        );
        await signOut;
        await tester.pumpAndSettle();

        expect(find.text('Pilot page'), findsNothing);
        expect(sessions.read(), isNull);
        expect(endCalls, [
          '/sign-out-teardown',
        ], reason: 'the page must not end the session itself either');
      },
    );

    testWidgets(
      'Home recreated during a sign-out does not start a second one',
      (tester) async {
        final auth = _FakeAuth();
        await auth.signIn();
        final sessions = MemoryGuestSessionStore()..write(stored);
        final gate = ContestOpenGate();
        final endAnswer = Completer<void>();
        final endCalls = <String>[];
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
            GoRoute(
              path: contestsPath,
              builder: (context, state) =>
                  const Scaffold(body: Text('Contests page')),
            ),
          ],
        );
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          AuthScope(
            session: auth,
            child: ApiClientInherited(
              client: ApiClient(
                baseUrl: Uri.parse('http://localhost:8080'),
                httpClient: MockClient((request) async {
                  endCalls.add(request.url.path);
                  await endAnswer.future;
                  return http.Response('', 204);
                }),
              ),
              child: GuestSessionScope(
                store: sessions,
                child: ContestOpenScope(
                  gate: gate,
                  child: MaterialApp.router(
                    localizationsDelegates: appLocalizationDelegates,
                    routerConfig: router,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
        await tester.pump();
        expect(gate.isSigningOut, isTrue);

        // Leave Home and come back: a new Home starts signing out again.
        router.go(contestsPath);
        await tester.pumpAndSettle();
        router.go('/');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
        await tester.pump();

        expect(endCalls, hasLength(1), reason: 'one teardown, not two');
        endAnswer.complete();
        await tester.pumpAndSettle();

        expect(endCalls, hasLength(1));
        expect(auth.isSignedIn, isFalse);
        expect(gate.isClosed, isFalse);
      },
    );

    testWidgets('a server that cannot end it keeps the pilot signed in', (
      tester,
    ) async {
      final auth = _FakeAuth();
      await auth.signIn();
      final sessions = MemoryGuestSessionStore()..write(stored);
      await _pump(
        tester,
        auth,
        sessions: sessions,
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost:8080'),
          httpClient: MockClient((_) async => http.Response('', 500)),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(
        find.text('Sign-out could not be completed. Try again.'),
        findsOneWidget,
      );
      expect(auth.isSignedIn, isTrue);
      expect(sessions.read(), isNotNull, reason: 'so a retry can end it');
    });

    testWidgets('a session the server already dropped does not block it', (
      tester,
    ) async {
      final auth = _FakeAuth();
      await auth.signIn();
      final sessions = MemoryGuestSessionStore()..write(stored);
      await _pump(
        tester,
        auth,
        sessions: sessions,
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost:8080'),
          httpClient: MockClient((_) async => http.Response('', 401)),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(auth.isSignedIn, isFalse);
      expect(sessions.read(), isNull);
    });
  });

  testWidgets('a sign-out that fails says so and stays signed in', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await auth.signIn();
    auth.failSignOut = true;
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-out could not be completed. Try again.'), findsOne);
    expect(auth.isSignedIn, isTrue);
  });

  test('the E2E session gives the E2E server its pilot token', () async {
    final auth = E2eAuthSession();
    expect(await auth.accessToken(), isNull);
    await auth.signIn();
    expect(await auth.accessToken(), e2ePilotToken);
    await auth.signOut();
    expect(await auth.accessToken(), isNull);
  });

  testWidgets('Sign out is off while pending, and retry stays on offer', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await auth.signIn();
    auth.signOutGate = Completer<void>();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pump();
    // The request is out: the page stays signed in and the button is off, so
    // a second tap cannot send a second request.
    expect(find.text('Signed in as Penny Pilot'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Sign out'),
          )
          .onPressed,
      isNull,
    );

    auth.failSignOut = true;
    auth.signOutGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Sign-out could not be completed. Try again.'), findsOne);
    expect(find.text('Signed in as Penny Pilot'), findsOneWidget);
    final retry = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sign out'),
    );
    expect(retry.onPressed, isNotNull);

    auth
      ..failSignOut = false
      ..signOutGate = null;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(auth.calls.where((c) => c == 'sign-out'), hasLength(2));
  });

  testWidgets('both sign-in buttons are off while Auth0 starts', (
    tester,
  ) async {
    final auth = _FakeAuth()..initializing = true;
    await _pump(tester, auth);

    FilledButton signIn() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sign in'),
    );
    OutlinedButton signUp() => tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sign up'),
    );
    expect(signIn().onPressed, isNull);
    expect(signUp().onPressed, isNull);

    auth.initializing = false;
    auth.notifyListeners();
    await tester.pump();
    expect(signIn().onPressed, isNotNull);
    expect(signUp().onPressed, isNotNull);
  });

  testWidgets('a second sign-in tap while one is out is ignored', (
    tester,
  ) async {
    final auth = _FakeAuth()..signInGate = Completer<void>();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    // The first is out: both controls are off, so no second call can start.
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Sign up'),
          )
          .onPressed,
      isNull,
    );
    expect(auth.calls, ['sign-in']);

    auth.signInGate!.complete();
    await tester.pumpAndSettle();
  });
}
