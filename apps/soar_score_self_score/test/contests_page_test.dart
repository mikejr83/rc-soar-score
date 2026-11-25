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
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/pages/contests_page.dart';
import 'package:soar_score_self_score/public_site.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

ContestSummary _contest(
  String id,
  String name,
  ContestPhase phase, {
  Uri? results,
  String? location,
}) => ContestSummary(
  participationId: 'p-$id',
  contestId: 'c-$id',
  name: name,
  startDate: DateTime.utc(2026, 10, 10),
  endDate: DateTime.utc(2026, 10, 11),
  phase: phase,
  location: location,
  publicResultsUrl: results,
);

class _Repository extends SampleSelfScoreRepository {
  _Repository(this.view, {this.openError});

  ContestsView view;
  Object? openError;
  final opened = <String>[];
  int loads = 0;

  @override
  Future<ContestsView> contests() async {
    loads++;
    return view;
  }

  @override
  Future<GuestSession> openContest(String participationId) async {
    opened.add(participationId);
    final error = openError;
    if (error != null) throw error;
    return GuestSession(
      contestId: 'c-open',
      contestName: 'Opened',
      pilotId: 'pilot-9',
      pilotName: 'Penny Pilot',
      token: 't',
      expiresAt: DateTime.utc(2099),
    );
  }
}

Future<MemoryGuestSessionStore> _pump(
  WidgetTester tester,
  SelfScoreRepository repository, {
  AuthSession? auth,
  UrlOpener? opener,
  ApiClient? client,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = MemoryGuestSessionStore();
  final session = auth ?? (E2eAuthSession()..signIn());
  Widget wrap(Widget child) =>
      client == null ? child : ApiClientInherited(client: client, child: child);
  await tester.pumpWidget(
    AuthScope(
      session: session,
      child: GuestSessionScope(
        store: store,
        child: SelfScoreScope(
          repository: repository,
          child: wrap(
            MaterialApp.router(
              localizationsDelegates: appLocalizationDelegates,
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => opener == null
                        ? const ContestsPage()
                        : ContestsPage(opener: opener),
                  ),
                  GoRoute(
                    path: '/contests/:contestId/pilots/:pilotId',
                    builder: (context, state) => Scaffold(
                      body: Text('Pilot ${state.pathParameters['pilotId']}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('groups contests as in progress, invited and completed', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repository(
        ContestsView(
          contests: [
            _contest('a', 'Done Cup', ContestPhase.completed),
            _contest('b', 'Spring Open', ContestPhase.invited),
            _contest(
              'c',
              'Club Day',
              ContestPhase.inProgress,
              location: 'Denver, CO',
            ),
          ],
        ),
      ),
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    int at(String text) => texts.indexOf(text);
    expect(at('Club Day'), lessThan(at('Spring Open')));
    expect(at('Spring Open'), lessThan(at('Done Cup')));
    expect(find.text('Denver, CO'), findsOneWidget);
    expect(find.text('Sat, Oct 10, 2026 to Sun, Oct 11, 2026'), findsWidgets);
    expect(
      find.text('Completed contests stay on this list for a day.'),
      findsOneWidget,
    );
  });

  testWidgets('a section with no contest has no heading', (tester) async {
    await _pump(
      tester,
      _Repository(
        ContestsView(
          contests: [_contest('b', 'Spring Open', ContestPhase.invited)],
        ),
      ),
    );

    // The heading and the card's status chip.
    expect(find.text('Invited'), findsNWidgets(2));
    expect(find.text('In progress'), findsNothing);
    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('with no contest it says how one gets here', (tester) async {
    await _pump(tester, _Repository(const ContestsView(contests: [])));

    expect(find.text('No contests yet'), findsOneWidget);
    expect(find.textContaining('invites you'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('signed out it offers Sign in and loads nothing', (tester) async {
    final repository = _Repository(const ContestsView(contests: []));
    final auth = E2eAuthSession();
    await _pump(tester, repository, auth: auth);

    expect(
      find.text('Sign in to see the contests you are in.'),
      findsOneWidget,
    );
    expect(repository.loads, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isTrue);
    expect(repository.loads, 1);
  });

  testWidgets('with no sign-in provider the button is off and says why', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repository(const ContestsView(contests: [])),
      auth: UnavailableAuthSession(),
    );

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('coming in a future release'), findsOneWidget);
  });

  testWidgets('a sign-in that cannot start says so', (tester) async {
    await _pump(
      tester,
      _Repository(const ContestsView(contests: [])),
      auth: _RefusingAuth(),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sign-in could not be started. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('a list the server refuses offers signing in again', (
    tester,
  ) async {
    final auth = _FakeSignIn();
    await _pump(tester, _SignedOutRepository(), auth: auth);

    expect(find.textContaining('Your sign-in has ended'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(auth.signIns, 1);
  });

  testWidgets('an open the server refuses offers signing in again', (
    tester,
  ) async {
    final auth = _FakeSignIn();
    final repository = _Repository(
      ContestsView(
        contests: [_contest('b', 'Spring Open', ContestPhase.invited)],
      ),
      openError: const SignedOutException(),
    );
    final store = await _pump(tester, repository, auth: auth);
    store.write(
      GuestSession(
        contestId: 'c',
        contestName: 'n',
        pilotId: 'p',
        pilotName: 'x',
        expiresAt: DateTime.utc(2099),
      ),
    );

    await tester.tap(find.text('Spring Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, 'Sign in'));
    await tester.pumpAndSettle();

    expect(auth.signIns, 1);
    expect(store.read(), isNotNull, reason: 'guest scoring access is kept');
  });

  testWidgets('signing out while a contest opens drops what it opened', (
    tester,
  ) async {
    final gate = Completer<GuestSession>();
    final auth = E2eAuthSession()..signIn();
    final repository = _GatedRepository(gate.future);
    final ended = <String>[];
    final store = await _pump(
      tester,
      repository,
      auth: auth,
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost:8080'),
        httpClient: MockClient((request) async {
          ended.add('${request.method} ${request.url.path}');
          return http.Response('', 204);
        }),
      ),
    );

    await tester.tap(find.text('Spring Open'));
    await tester.pump();
    await auth.signOut();
    gate.complete(
      GuestSession(
        contestId: 'c-open',
        contestName: 'Opened',
        pilotId: 'pilot-9',
        pilotName: 'Penny Pilot',
        expiresAt: DateTime.utc(2099),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.read(), isNull);
    expect(ended, ['POST /api/v1/self-scoring/session/end']);
    expect(find.text('Pilot pilot-9'), findsNothing);
  });

  testWidgets('tapping a contest opens it as the pilot', (tester) async {
    final repository = _Repository(
      ContestsView(
        contests: [_contest('b', 'Spring Open', ContestPhase.invited)],
      ),
    );
    final store = await _pump(tester, repository);

    await tester.tap(find.text('Spring Open'));
    await tester.pumpAndSettle();

    expect(repository.opened, ['p-b']);
    expect(find.text('Pilot pilot-9'), findsOneWidget);
    expect(store.read()?.contestId, 'c-open');
  });

  testWidgets('a contest that left the list says so and the list reloads', (
    tester,
  ) async {
    final repository = _Repository(
      ContestsView(
        contests: [_contest('b', 'Spring Open', ContestPhase.invited)],
      ),
      openError: const ContestNotOnListException(),
    );
    final store = await _pump(tester, repository);

    await tester.tap(find.text('Spring Open'));
    await tester.pumpAndSettle();

    expect(
      find.text('This contest is no longer on your list.'),
      findsOneWidget,
    );
    expect(repository.loads, 2);
    expect(store.read(), isNull);
  });

  testWidgets('a failed open says so and stays on the list', (tester) async {
    final repository = _Repository(
      ContestsView(
        contests: [_contest('b', 'Spring Open', ContestPhase.invited)],
      ),
      openError: const SelfScoreOfflineException('offline'),
    );
    await _pump(tester, repository);

    await tester.tap(find.text('Spring Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not open this contest'), findsOneWidget);
    expect(find.text('Spring Open'), findsOneWidget);
  });

  testWidgets('public results open from the card, and only when public', (
    tester,
  ) async {
    final opened = <Uri>[];
    await _pump(
      tester,
      _Repository(
        ContestsView(
          contests: [
            _contest(
              'a',
              'Public Cup',
              ContestPhase.completed,
              results: Uri.parse('https://rcsoarscore.com/results/contests/x'),
            ),
            _contest('b', 'Private Day', ContestPhase.invited),
          ],
        ),
      ),
      opener: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(find.text('Public results'), findsOneWidget);
    await tester.tap(find.text('Public results'));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://rcsoarscore.com/results/contests/x')]);
  });

  testWidgets(
    'a sign-in the server refuses says so, offers sign-in and keeps the guest',
    (tester) async {
      final repository = _SignedOutRepository();
      final store = await _pump(tester, repository);
      store.write(
        GuestSession(
          contestId: 'c',
          contestName: 'n',
          pilotId: 'p',
          pilotName: 'x',
          expiresAt: DateTime.utc(2099),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Your sign-in has ended'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(store.read(), isNotNull);
    },
  );
}

class _FakeSignIn extends E2eAuthSession {
  _FakeSignIn() {
    super.signIn();
  }

  int signIns = 0;

  @override
  Future<void> signIn({bool createAccount = false}) async {
    signIns++;
  }
}

class _RefusingAuth extends E2eAuthSession {
  @override
  Future<void> signIn({bool createAccount = false}) async =>
      throw const AuthException('no');
}

class _GatedRepository extends _Repository {
  _GatedRepository(this.gate)
    : super(
        ContestsView(
          contests: [_contest('b', 'Spring Open', ContestPhase.invited)],
        ),
      );

  final Future<GuestSession> gate;

  @override
  Future<GuestSession> openContest(String participationId) => gate;
}

class _SignedOutRepository extends SampleSelfScoreRepository {
  @override
  Future<ContestsView> contests() async => throw const SignedOutException();
}
