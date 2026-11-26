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
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/models/own_directory.dart';
import 'package:soar_score_self_score/pages/contests_page.dart';
import 'package:soar_score_self_score/pages/details_page.dart';
import 'package:soar_score_self_score/pages/home_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

/// A pilot with no directory entry yet (#652) or with one.
class _Repository extends SampleSelfScoreRepository {
  _Repository({
    this.saveGate,
    this.hasEntry = false,
    this.saveError,
    this.loadError,
    this.initial = const DirectoryDetails(
      firstName: 'Penny',
      lastName: 'Pilot',
    ),
  });

  final DirectoryDetails initial;

  /// Holds a save until completed.
  final Completer<void>? saveGate;

  final bool hasEntry;
  Object? saveError;
  final Object? loadError;
  final saved = <DirectoryDetails>[];
  int looks = 0;

  @override
  Future<OwnDirectory> ownDirectory() async {
    looks++;
    final error = loadError;
    if (error != null) throw error;
    return OwnDirectory(
      hasEntry: hasEntry,
      emailAvailable: true,
      initial: initial,
    );
  }

  @override
  Future<void> saveOwnDirectory(DirectoryDetails details) async {
    await saveGate?.future;
    final error = saveError;
    if (error != null) throw error;
    saved.add(details);
  }

  @override
  Future<ContestsView> contests() async => const ContestsView(contests: []);

  @override
  Future<List<Never>> linkCandidates() async => const [];
}

Future<E2eAuthSession> _pump(
  WidgetTester tester,
  SelfScoreRepository repository, {
  String initial = '/',
  bool signedIn = true,
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
              GoRoute(path: '/', builder: (_, _) => const HomePage()),
              GoRoute(
                path: '/elsewhere',
                builder: (_, _) => const Scaffold(body: Text('Elsewhere')),
              ),
              GoRoute(
                path: detailsPath,
                builder: (_, _) => const DetailsPage(),
              ),
              GoRoute(
                path: contestsPath,
                builder: (_, _) => const ContestsPage(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

http.Response _json(String body, [int status = 200]) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _noEntry =
    '{"entry":null,"suggested_first_name":"Penny","suggested_last_name":"Pilot",'
    '"email_available":true}';

/// The real repository over a server that answers [put] to the save and
/// [get] to the lookup.
ApiSelfScoreRepository _api({int get = 200, int put = 200}) =>
    ApiSelfScoreRepository(
      ApiClient(
        baseUrl: Uri.parse('http://localhost:8080'),
        httpClient: MockClient(
          (request) async => request.method == 'GET'
              ? _json(get == 200 ? _noEntry : '{}', get)
              : _json(put == 200 ? _noEntry : '{}', put),
        ),
        tokenProvider: () async => 't',
      ),
      MemoryGuestSessionStore(),
    );

void main() {
  group('first sign-in', () {
    testWidgets('a pilot with no entry is sent to the details page', (
      tester,
    ) async {
      await _pump(tester, _Repository());

      expect(find.text('Your details'), findsWidgets);
      expect(find.byKey(const Key('details-continue')), findsOneWidget);
    });

    testWidgets('a pilot with an entry stays on the landing page', (
      tester,
    ) async {
      await _pump(tester, _Repository(hasEntry: true));

      expect(find.byKey(const Key('details-continue')), findsNothing);
      expect(find.text('My contests'), findsOneWidget);
    });

    testWidgets('a failed look leaves the pilot where they are', (
      tester,
    ) async {
      await _pump(
        tester,
        _Repository(loadError: const SelfScoreLoadException('down')),
      );

      expect(find.text('My contests'), findsOneWidget);
    });

    testWidgets('signed out, nothing is looked up', (tester) async {
      final repository = _Repository();
      await _pump(tester, repository, signedIn: false);

      expect(repository.looks, 0);
    });
  });

  group('details page', () {
    testWidgets('starts with find-me ticked, email private and the name', (
      tester,
    ) async {
      await _pump(tester, _Repository(), initial: detailsPath);

      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('details-listed')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('details-email-private')),
            )
            .value,
        isTrue,
      );
      expect(find.widgetWithText(TextFormField, 'Penny'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Pilot'), findsOneWidget);
    });

    testWidgets('Continue saves the defaults and goes to the contests', (
      tester,
    ) async {
      final repository = _Repository();
      await _pump(tester, repository, initial: detailsPath);

      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();

      final saved = repository.saved.single;
      expect(saved.firstName, 'Penny');
      expect(saved.lastName, 'Pilot');
      expect(saved.isListed, isTrue);
      expect(saved.emailVisibleToDirectors, isFalse);
      expect(find.text('Contests'), findsWidgets);
      expect(find.byKey(const Key('details-continue')), findsNothing);
    });

    testWidgets('unticked boxes and optional details are saved', (
      tester,
    ) async {
      final repository = _Repository();
      await _pump(tester, repository, initial: detailsPath);

      await tester.tap(find.byKey(const Key('details-listed')));
      await tester.tap(find.byKey(const Key('details-email-private')));
      await tester.tap(find.byKey(const Key('details-more')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('details-fai')), ' 1234 ');
      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();

      final saved = repository.saved.single;
      expect(saved.isListed, isFalse);
      expect(saved.emailVisibleToDirectors, isTrue);
      expect(saved.faiNumber, '1234');
    });

    testWidgets('city and state of an existing entry survive a save', (
      tester,
    ) async {
      final repository = _Repository(
        hasEntry: true,
        initial: const DirectoryDetails(
          firstName: 'Penny',
          lastName: 'Pilot',
          city: 'Boulder',
          state: 'CO',
        ),
      );
      await _pump(tester, repository, initial: detailsPath);

      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();
      expect(repository.saved.last.city, 'Boulder');
      expect(repository.saved.last.state, 'CO');

      await _pump(tester, repository, initial: detailsPath);
      await tester.enterText(
        find.byKey(const Key('details-first-name')),
        'Pen',
      );
      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();
      expect(repository.saved.last.firstName, 'Pen');
      expect(repository.saved.last.city, 'Boulder');
      expect(repository.saved.last.state, 'CO');
    });

    testWidgets('a save that finishes after the pilot left stays put', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repository = _Repository(saveGate: gate);
      await _pump(tester, repository, initial: detailsPath);

      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pump();
      GoRouter.of(tester.element(find.byKey(const Key('details-continue'))))
          .go('/elsewhere');
      await tester.pumpAndSettle();
      expect(find.text('Elsewhere'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repository.saved, hasLength(1));
      expect(find.text('Elsewhere'), findsOneWidget);
      expect(find.byKey(const Key('directory-prompt')), findsNothing);
    });

    testWidgets('the inputs are off while a save is out', (tester) async {
      final gate = Completer<void>();
      final repository = _Repository(saveGate: gate);
      await _pump(tester, repository, initial: detailsPath);

      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pump();
      // Attempts to change the choices and a field are ignored.
      await tester.tap(find.byKey(const Key('details-listed')));
      await tester.tap(find.byKey(const Key('details-email-private')));
      await tester.enterText(find.byKey(const Key('details-first-name')), 'X');
      await tester.pump();

      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('details-listed')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('details-email-private')),
            )
            .value,
        isTrue,
      );
      expect(find.widgetWithText(TextFormField, 'Penny'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      final saved = repository.saved.single;
      expect(saved.isListed, isTrue);
      expect(saved.emailVisibleToDirectors, isFalse);
      expect(saved.firstName, 'Penny');
    });

    testWidgets('a blank name is not saved', (tester) async {
      final repository = _Repository();
      await _pump(tester, repository, initial: detailsPath);

      await tester.enterText(find.byKey(const Key('details-first-name')), ' ');
      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(repository.saved, isEmpty);
    });

    testWidgets('a failed save says so and stays', (tester) async {
      final repository = _Repository(
        saveError: const SelfScoreLoadException('down'),
      );
      await _pump(tester, repository, initial: detailsPath);

      await tester.tap(find.byKey(const Key('details-continue')));
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(find.byKey(const Key('details-continue')), findsOneWidget);
    });

    testWidgets('signed out goes back to the landing page', (tester) async {
      await _pump(tester, _Repository(), initial: detailsPath, signedIn: false);

      expect(find.byKey(const Key('details-continue')), findsNothing);
      expect(find.text('Sign in'), findsWidgets);
    });
  });

  group('server refusals', () {
    for (final status in [404, 409]) {
      testWidgets('a $status on save shows the save-failed message', (
        tester,
      ) async {
        await _pump(tester, _api(put: status), initial: detailsPath);

        await tester.tap(find.byKey(const Key('details-continue')));
        await tester.pumpAndSettle();

        expect(find.textContaining('could not be saved'), findsOneWidget);
        expect(find.byKey(const Key('details-continue')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a $status on the landing lookup leaves the pilot there', (
        tester,
      ) async {
        await _pump(tester, _api(get: status));

        expect(find.text('My contests'), findsOneWidget);
        expect(find.byKey(const Key('details-continue')), findsNothing);
        expect(tester.takeException(), isNull);
      });

      test('a $status is a load failure for both calls', () async {
        final api = _api(get: status, put: status);

        await expectLater(
          api.ownDirectory(),
          throwsA(isA<SelfScoreLoadException>()),
        );
        await expectLater(
          api.saveOwnDirectory(
            const DirectoryDetails(firstName: 'Pat', lastName: 'Pilot'),
          ),
          throwsA(isA<SelfScoreLoadException>()),
        );
      });
    }
  });

  group('contests page card', () {
    testWidgets('a pilot with no entry is asked, and the card opens the page', (
      tester,
    ) async {
      await _pump(tester, _Repository(), initial: contestsPath);

      expect(find.byKey(const Key('directory-prompt')), findsOneWidget);
      await tester.tap(find.text('Set your details'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('details-continue')), findsOneWidget);
    });

    testWidgets('a pilot with an entry has no card', (tester) async {
      await _pump(tester, _Repository(hasEntry: true), initial: contestsPath);

      expect(find.byKey(const Key('directory-prompt')), findsNothing);
    });
  });

  group('repository', () {
    ApiSelfScoreRepository repository(
      http.Response Function(http.Request) respond,
    ) => ApiSelfScoreRepository(
      ApiClient(
        baseUrl: Uri.parse('http://localhost:8080'),
        httpClient: MockClient((request) async => respond(request)),
        tokenProvider: () async => 't',
      ),
      MemoryGuestSessionStore(),
    );

    http.Response json(String body, [int status = 200]) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

    test('no entry starts from the account name with the defaults', () async {
      final result = await repository(
        (_) => json(
          '{"entry":null,"suggested_first_name":"Pat","suggested_last_name":"Pilot",'
          '"email_available":true}',
        ),
      ).ownDirectory();

      expect(result.hasEntry, isFalse);
      expect(result.initial.firstName, 'Pat');
      expect(result.initial.isListed, isTrue);
      expect(result.initial.emailVisibleToDirectors, isFalse);
    });

    test('a saved entry is read as it is', () async {
      final result = await repository(
        (_) => json(
          '{"entry":{"id":"019c0000-0000-7000-8000-000000000001",'
          '"first_name":"Pat","last_name":"Pilot","club":"Soar",'
          '"fai_number":null,"national_org_id":null,"city":null,"state":null,'
          '"country":null,"is_listed":false,"email_visible_to_directors":true,'
          '"created_at":"2026-11-25T12:00:00.000Z",'
          '"updated_at":"2026-11-25T12:00:00.000Z"},'
          '"suggested_first_name":"Pat","suggested_last_name":"Pilot",'
          '"email_available":false}',
        ),
      ).ownDirectory();

      expect(result.hasEntry, isTrue);
      expect(result.initial.club, 'Soar');
      expect(result.initial.isListed, isFalse);
      expect(result.initial.emailVisibleToDirectors, isTrue);
      expect(result.emailAvailable, isFalse);
    });

    test('a saved entry keeps city and state through a save', () async {
      final requests = <http.Request>[];
      final api = repository((request) {
        requests.add(request);
        return json(
          request.method == 'GET'
              ? '{"entry":{"id":"019c0000-0000-7000-8000-000000000001",'
                    '"first_name":"Pat","last_name":"Pilot","club":null,'
                    '"fai_number":null,"national_org_id":null,'
                    '"city":"Boulder","state":"CO","country":null,'
                    '"is_listed":true,"email_visible_to_directors":false,'
                    '"created_at":"2026-11-25T12:00:00.000Z",'
                    '"updated_at":"2026-11-25T12:00:00.000Z"},'
                    '"suggested_first_name":"Pat","suggested_last_name":"Pilot",'
                    '"email_available":true}'
              : '{"entry":null,"suggested_first_name":"Pat",'
                    '"suggested_last_name":"Pilot","email_available":true}',
        );
      });

      final loaded = await api.ownDirectory();
      await api.saveOwnDirectory(loaded.initial);

      final put = requests.last;
      expect(put.method, 'PUT');
      expect(put.body, contains('"city":"Boulder"'));
      expect(put.body, contains('"state":"CO"'));
    });

    test('saving sends the details to the entry route', () async {
      http.Request? sent;
      await repository((request) {
        sent = request;
        return json(
          '{"entry":null,"suggested_first_name":"Pat","suggested_last_name":"Pilot",'
          '"email_available":true}',
        );
      }).saveOwnDirectory(
        const DirectoryDetails(firstName: 'Pat', lastName: 'Pilot'),
      );

      expect(sent!.method, 'PUT');
      expect(sent!.url.path, '/api/v1/account/directory-entry');
      expect(sent!.body, contains('"is_listed":true'));
      expect(sent!.body, contains('"email_visible_to_directors":false'));
    });

    test('a failure is a load failure', () async {
      expect(
        repository((_) => json('{}', 500)).ownDirectory(),
        throwsA(isA<SelfScoreLoadException>()),
      );
    });
  });
}
