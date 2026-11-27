import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_self_score/auth/auth_scope.dart';
import 'package:soar_score_self_score/auth/e2e_auth_session.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/account_link.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/models/own_directory.dart';
import 'package:soar_score_self_score/pages/account_page.dart';
import 'package:soar_score_self_score/pages/contests_page.dart';
import 'package:soar_score_self_score/pages/details_page.dart';
import 'package:soar_score_self_score/pages/home_page.dart';
import 'package:soar_score_self_score/router.dart';

/// A sign-in whose restore is still running until the test finishes it, and
/// that counts the sign-ins it is asked for.
class _RestoringAuth extends E2eAuthSession {
  bool initializing = true;
  int signIns = 0;

  @override
  bool get isInitializing => initializing;

  void finishRestore({required bool signedIn}) {
    initializing = false;
    if (signedIn) {
      super.signIn();
    } else {
      notifyListeners();
    }
  }

  @override
  Future<void> signIn({bool createAccount = false, String? returnTo}) async {
    signIns++;
    await super.signIn(createAccount: createAccount, returnTo: returnTo);
  }
}

/// A repository whose account routes can answer "signed out".
class _Repository extends SampleSelfScoreRepository {
  _Repository({this.signedOut = false});

  /// Every account route throws [SignedOutException] while true.
  bool signedOut;
  int looks = 0;

  void _check() {
    if (signedOut) throw const SignedOutException();
  }

  @override
  Future<OwnDirectory> ownDirectory() async {
    looks++;
    _check();
    return const OwnDirectory(
      hasEntry: true,
      emailAvailable: true,
      initial: DirectoryDetails(firstName: 'Penny', lastName: 'Pilot'),
    );
  }

  @override
  Future<void> saveOwnDirectory(DirectoryDetails details) async => _check();

  @override
  Future<List<AccountLink>> accountLinks() async {
    _check();
    return const [AccountLink(id: 'link-1', pilotName: 'Penny Pilot')];
  }

  @override
  Future<void> endAccountLink(String linkId) async => _check();

  @override
  Future<ContestsView> contests() async {
    _check();
    return const ContestsView(contests: []);
  }

  @override
  Future<List<Never>> linkCandidates() async => const [];
}

Future<GoRouter> _pump(
  WidgetTester tester,
  _RestoringAuth auth,
  SelfScoreRepository repository, {
  required String initial,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: contestsPath, builder: (_, _) => const ContestsPage()),
      GoRoute(path: accountPath, builder: (_, _) => const AccountPage()),
      GoRoute(path: detailsPath, builder: (_, _) => const DetailsPage()),
    ],
  );
  await tester.pumpWidget(
    AuthScope(
      session: auth,
      child: SelfScoreScope(
        repository: repository,
        child: MaterialApp.router(
          localizationsDelegates: appLocalizationDelegates,
          routerConfig: router,
        ),
      ),
    ),
  );
  // A page still loading shows a spinner that never settles.
  settle ? await tester.pumpAndSettle() : await tester.pump();
  return router;
}

String _path(GoRouter router) => router.routeInformationProvider.value.uri.path;

void main() {
  group('while the sign-in is being restored', () {
    for (final path in [contestsPath, accountPath, detailsPath]) {
      testWidgets('$path shows a loading state, then the page', (tester) async {
        final auth = _RestoringAuth();
        final repository = _Repository();
        final router = await _pump(
          tester,
          auth,
          repository,
          initial: path,
          settle: false,
        );

        // No sign-in prompt, no bounce to the landing page, nothing blank.
        expect(find.bySemanticsLabel('Loading'), findsOneWidget);
        expect(find.text('Sign in'), findsNothing);
        expect(_path(router), path);
        expect(repository.looks, 0, reason: 'nothing is loaded yet');

        auth.finishRestore(signedIn: true);
        await tester.pumpAndSettle();

        expect(_path(router), path);
        expect(find.text('Sign in'), findsNothing);
        if (path != contestsPath) expect(repository.looks, greaterThan(0));
      });

      testWidgets('$path leaves a pilot who turns out signed out', (
        tester,
      ) async {
        final auth = _RestoringAuth();
        final router = await _pump(
          tester,
          auth,
          _Repository(),
          initial: path,
          settle: false,
        );

        auth.finishRestore(signedIn: false);
        await tester.pumpAndSettle();

        if (path == contestsPath) {
          // The contests page shows its own sign-in prompt.
          expect(find.text('Sign in'), findsWidgets);
          expect(_path(router), contestsPath);
        } else {
          expect(_path(router), '/');
        }
      });
    }
  });

  group('when the server stops accepting the sign-in', () {
    testWidgets('the account page offers signing in again', (tester) async {
      final auth = _RestoringAuth()..finishRestore(signedIn: true);
      await _pump(
        tester,
        auth,
        _Repository(signedOut: true),
        initial: accountPath,
      );

      expect(find.textContaining('Your sign-in has ended'), findsOneWidget);
      expect(find.textContaining('Could not reach'), findsNothing);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(auth.signIns, 1);
    });

    testWidgets('a failed unlink offers signing in again', (tester) async {
      final auth = _RestoringAuth()..finishRestore(signedIn: true);
      final repository = _Repository();
      await _pump(tester, auth, repository, initial: accountPath);

      repository.signedOut = true;
      await tester.tap(find.byKey(const Key('account-unlink-link-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-unlink-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(SnackBarAction, 'Sign in again'),
        findsOneWidget,
      );
      expect(find.textContaining('could not be ended'), findsNothing);
    });

    testWidgets('a failed details save offers signing in again', (
      tester,
    ) async {
      final auth = _RestoringAuth()..finishRestore(signedIn: true);
      final repository = _Repository();
      await _pump(tester, auth, repository, initial: detailsPath);

      repository.signedOut = true;
      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Your sign-in has ended'), findsOneWidget);
      expect(find.textContaining('could not be saved'), findsNothing);
      await tester.tap(find.byKey(const Key('details-sign-in-again')));
      await tester.pumpAndSettle();
      expect(auth.signIns, 1);
    });
  });

  group('the details page after sign-in', () {
    testWidgets('is offered once per sign-in, not on every landing visit', (
      tester,
    ) async {
      final auth = _RestoringAuth()..finishRestore(signedIn: true);
      final repository = _NoEntry();
      final router = await _pump(tester, auth, repository, initial: '/');
      expect(_path(router), detailsPath, reason: 'first look sends them');

      // The pilot declines (leaves), then opens the landing page again.
      router.go(contestsPath);
      await tester.pumpAndSettle();
      router.go('/');
      await tester.pumpAndSettle();

      expect(_path(router), '/', reason: 'not sent again');

      // A new sign-in is a new session.
      await auth.signOut();
      await auth.signIn();
      router.go('/');
      await tester.pumpAndSettle();
      expect(_path(router), detailsPath);
    });
  });
}

/// A pilot who never has a directory entry.
class _NoEntry extends _Repository {
  @override
  Future<OwnDirectory> ownDirectory() async {
    looks++;
    return const OwnDirectory(
      hasEntry: false,
      emailAvailable: true,
      initial: DirectoryDetails(firstName: 'Penny', lastName: 'Pilot'),
    );
  }
}
