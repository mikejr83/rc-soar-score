import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/auth/auth_scope.dart';
import 'package:soar_score_self_score/auth/e2e_auth_session.dart';
import 'package:soar_score_self_score/data/api_self_score_repository.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/account_link.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/models/own_directory.dart';
import 'package:soar_score_self_score/pages/account_page.dart';
import 'package:soar_score_self_score/pages/details_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

/// A pilot with a directory entry and some links (#654).
class _Repository extends SampleSelfScoreRepository {
  _Repository({
    List<AccountLink>? links,
    this.hasEntry = true,
    this.endError,
    this.endGate,
    this.removeError,
  }) : links = links ?? [..._twoLinks];

  final List<AccountLink> links;
  final bool hasEntry;
  Object? endError;
  Object? removeError;
  final Completer<void>? endGate;
  final ended = <String>[];
  int removed = 0;
  final saved = <DirectoryDetails>[];

  @override
  Future<OwnDirectory> ownDirectory() async => OwnDirectory(
    hasEntry: hasEntry && removed == 0,
    emailAvailable: true,
    initial: const DirectoryDetails(
      firstName: 'Penny',
      lastName: 'Pilot',
      isListed: false,
    ),
  );

  @override
  Future<void> saveOwnDirectory(DirectoryDetails details) async =>
      saved.add(details);

  @override
  Future<void> deleteOwnDirectory() async {
    final error = removeError;
    if (error != null) throw error;
    removed++;
  }

  @override
  Future<List<AccountLink>> accountLinks() async => [...links];

  @override
  Future<void> endAccountLink(String linkId) async {
    await endGate?.future;
    final error = endError;
    if (error != null) throw error;
    ended.add(linkId);
    links.removeWhere((link) => link.id == linkId);
  }

  @override
  Future<ContestsView> contests() async => const ContestsView(contests: []);

  @override
  Future<List<Never>> linkCandidates() async => const [];
}

const _twoLinks = [
  AccountLink(id: 'link-1', pilotName: 'Penny Pilot'),
  AccountLink(id: 'link-2', pilotName: 'P. Pilot'),
];

Future<void> _pump(
  WidgetTester tester,
  SelfScoreRepository repository, {
  bool signedIn = true,
  String initial = accountPath,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = E2eAuthSession();
  if (signedIn) await auth.signIn();
  await tester.pumpWidget(
    AuthScope(
      session: auth,
      child: SelfScoreScope(
        repository: repository,
        child: MaterialApp.router(
          localizationsDelegates: appLocalizationDelegates,
          routerConfig: GoRouter(
            initialLocation: initial,
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: Text('Start')),
              ),
              GoRoute(
                path: contestsPath,
                builder: (_, _) => const Scaffold(body: Text('Contests')),
              ),
              GoRoute(
                path: accountPath,
                builder: (_, _) => const AccountPage(),
              ),
              GoRoute(
                path: detailsPath,
                builder: (_, state) => DetailsPage(
                  returnToAccount:
                      state.uri.queryParameters['from'] == 'account',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

http.Response _json(String body, [int status = 200]) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _linkId = '01934e8a-7b3c-7000-8000-000000000007';

void main() {
  group('account page', () {
    testWidgets('shows the details and the linked pilots', (tester) async {
      await _pump(tester, _Repository());

      expect(find.text('Penny Pilot'), findsNWidgets(2)); // entry and link 1
      expect(find.text('P. Pilot'), findsOneWidget);
      expect(find.text('Contest directors cannot find you'), findsOneWidget);
      expect(find.text('Your email is private'), findsOneWidget);
      expect(find.byKey(const Key('account-unlink-link-1')), findsOneWidget);
    });

    testWidgets('says so when no pilot is linked', (tester) async {
      await _pump(tester, _Repository(links: []));

      expect(find.byKey(const Key('account-links-empty')), findsOneWidget);
    });

    testWidgets('a pilot with no entry is invited to set one', (tester) async {
      await _pump(tester, _Repository(hasEntry: false));

      expect(find.text('Set your details'), findsOneWidget);
      expect(find.byKey(const Key('account-remove-entry')), findsNothing);
    });

    testWidgets('signed out goes back to the start page', (tester) async {
      await _pump(tester, _Repository(), signedIn: false);

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('the back arrow goes to the contests', (tester) async {
      await _pump(tester, _Repository());

      await tester.tap(find.byTooltip('Back to contests'));
      await tester.pumpAndSettle();

      expect(find.text('Contests'), findsOneWidget);
    });
  });

  group('unlinking', () {
    testWidgets('says nothing published changes, and cancel changes nothing', (
      tester,
    ) async {
      final repository = _Repository();
      await _pump(tester, repository);

      await tester.tap(find.byKey(const Key('account-unlink-link-1')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nothing already published changes'),
        findsOneWidget,
      );
      expect(
        find.textContaining('invitation link still works'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('account-dialog-cancel')));
      await tester.pumpAndSettle();

      expect(repository.ended, isEmpty);
      expect(find.byKey(const Key('account-link-link-1')), findsOneWidget);
    });

    testWidgets('confirming ends the link and the pilot leaves the list', (
      tester,
    ) async {
      final repository = _Repository();
      await _pump(tester, repository);

      await tester.tap(find.byKey(const Key('account-unlink-link-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-unlink-confirm')));
      await tester.pumpAndSettle();

      expect(repository.ended, ['link-1']);
      expect(find.byKey(const Key('account-link-link-1')), findsNothing);
      expect(find.byKey(const Key('account-link-link-2')), findsOneWidget);
    });

    testWidgets('a failure keeps the link and says so', (tester) async {
      final repository = _Repository(
        endError: const SelfScoreLoadException('down'),
      );
      await _pump(tester, repository);

      await tester.tap(find.byKey(const Key('account-unlink-link-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-unlink-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The link could not be ended. Check your connection '
          'and try again.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('account-link-link-1')), findsOneWidget);
    });

    testWidgets('buttons are off while an unlink is out', (tester) async {
      final gate = Completer<void>();
      await _pump(tester, _Repository(endGate: gate));

      await tester.tap(find.byKey(const Key('account-unlink-link-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-unlink-confirm')));
      await tester.pump();

      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('account-unlink-link-2')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('account-edit-details')))
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
    });
  });

  group('directory entry', () {
    testWidgets('edit opens the details and saving comes back', (tester) async {
      final repository = _Repository();
      await _pump(tester, repository);

      await tester.tap(find.byKey(const Key('account-edit-details')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('details-continue')), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();

      expect(repository.saved, hasLength(1));
      expect(find.byKey(const Key('account-details')), findsOneWidget);
    });

    testWidgets('removing asks first, then drops the entry', (tester) async {
      final repository = _Repository();
      await _pump(tester, repository);

      await tester.tap(find.byKey(const Key('account-remove-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-dialog-cancel')));
      await tester.pumpAndSettle();
      expect(repository.removed, 0);

      await tester.tap(find.byKey(const Key('account-remove-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-remove-confirm')));
      await tester.pumpAndSettle();

      expect(repository.removed, 1);
      expect(find.text('Set your details'), findsOneWidget);
    });

    testWidgets('a failed removal says so', (tester) async {
      await _pump(
        tester,
        _Repository(removeError: const SelfScoreLoadException('down')),
      );

      await tester.tap(find.byKey(const Key('account-remove-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-remove-confirm')));
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be removed'), findsOneWidget);
    });
  });

  group('api repository', () {
    ApiSelfScoreRepository api(http.Response Function(http.Request) answer) =>
        ApiSelfScoreRepository(
          ApiClient(
            baseUrl: Uri.parse('http://localhost:8080'),
            httpClient: MockClient((request) async => answer(request)),
            tokenProvider: () async => 't',
          ),
          MemoryGuestSessionStore(),
        );

    test('lists the links with the pilots as typed', () async {
      final repository = api(
        (_) => _json(
          '{"links":[{"id":"$_linkId","pilot_name":"Penny Pilot",'
          '"status":"Confirmed","origin":"EmailMatch",'
          '"confirmed_at":"2026-11-01T10:00:00Z","ended_at":null}]}',
        ),
      );

      final links = await repository.accountLinks();

      expect(links.single.id, _linkId);
      expect(links.single.pilotName, 'Penny Pilot');
    });

    test('a link that is already gone counts as ended', () async {
      final repository = api(
        (_) => _json('{"code":"link_not_found","message":"x"}', 404),
      );

      await repository.endAccountLink(_linkId);
    });

    test('any other refusal is a load failure', () async {
      final repository = api((_) => _json('{}', 500));

      expect(
        () => repository.endAccountLink(_linkId),
        throwsA(isA<SelfScoreLoadException>()),
      );
    });

    test('removing the entry sends a DELETE', () async {
      final methods = <String>[];
      final repository = api((request) {
        methods.add('${request.method} ${request.url.path}');
        return http.Response('', 204);
      });

      await repository.deleteOwnDirectory();

      expect(methods, ['DELETE /api/v1/account/directory-entry']);
    });
  });
}
