import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
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
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = MemoryGuestSessionStore();
  final session = auth ?? (E2eAuthSession()..signIn());
  await tester.pumpWidget(
    AuthScope(
      session: session,
      child: GuestSessionScope(
        store: store,
        child: SelfScoreScope(
          repository: repository,
          child: MaterialApp.router(
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

  testWidgets('a sign-in the server refuses says so and keeps the guest', (
    tester,
  ) async {
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
    expect(find.text('Back to start'), findsOneWidget);
    expect(store.read(), isNotNull);
  });
}

class _SignedOutRepository extends SampleSelfScoreRepository {
  @override
  Future<ContestsView> contests() async => throw const SignedOutException();
}
